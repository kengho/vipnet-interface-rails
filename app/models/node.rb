class Node < AbstractModel
  belongs_to :network
  validates :network, presence: true
  has_many :node_ips, dependent: :destroy
  has_many :access_ips
  has_many :ips

  def self.vid_regexp
    /\A0x[0-9a-f]{8}\z/
  end

  validates :vid,
            presence: true,
            format: { with: Node.vid_regexp, message: "vid should be like \"#{Node.vid_regexp}\"" }

  def set_props_from_nodename(props)
    props.each do |prop, value|
      self[prop] = value if Nodename.props_from_api.include?(prop)
    end
  end

  def set_props_from_iplirconf(args)
    args.each do |coord_vid, snapshot|
      # there are only zero or one key in snapshot, because every other vid rejected
      if snapshot != {}
        props = snapshot[snapshot.keys.first]
        props.each do |prop, value|
          self[prop][coord_vid] = value if Iplirconf.props_from_api.include?(prop)
        end
      end
    end
  end

  def set_props_from_ticket
    TicketSystem.all.each do |ticket_system|
      tickets = Ticket.where(ticket_system: ticket_system, vid: self.vid)
      ticket_ids = []
      tickets.each { |t| ticket_ids.push(t.ticket_id) }
      # ticket_ids should be already unique because of validations, no need for "uniq"
      self.ticket[ticket_system.url_template] = ticket_ids.sort unless ticket_ids.empty?
    end
  end

  def self.version_decode(version)
    "3.0"
  end

  def self.where_vid_like(vid)
    search_resuls = CurrentNode.none
    normal_vids = VipnetParser::id(string: vid, threshold: Settings.vid_search_threshold)
    normal_vids.each do |normal_vid|
      search_resuls = search_resuls | CurrentNode.where("vid = ?", normal_vid)
    end
    search_resuls = search_resuls | CurrentNode.where("vid ILIKE ?", "%#{vid}%")
    search_resuls
  end

  def self.where_name_like(name)
    name_regexp = name.gsub(" ", ".*")
    search_resuls = CurrentNode.where("name ~* ?", name_regexp)
    search_resuls
  end

  def self.where_ip_like(ip)
    search_resuls = CurrentNode.none
    if IPv4::ip?(ip)
      search_resuls = CurrentNode.joins(:ips).where("u32 = ?", IPv4::u32(ip))
    end
    if IPv4::cidr(ip) || IPv4::range(ip)
      lower_bound, higher_bound = IPv4::u32_bounds(ip)
      search_resuls = CurrentNode.joins(:ips).where("u32 >= ? AND u32 <= ?", lower_bound, higher_bound)
    end
    search_resuls
  end

  def self.where_version_decoded_like(version_decoded)
    search_resuls = CurrentNode.none
    version_decoded_escaped = version_decoded.gsub("_", "\\\\_").gsub("%", "\\\\%")
    Coordinator.all.each do |coord|
      search_resuls = search_resuls | CurrentNode.where("version_decoded -> '#{coord.vid}' LIKE ?", "%#{version_decoded_escaped}%")
    end
    search_resuls
  end

  def self.where_creation_date_like(creation_date)
    self.where_date_like("creation_date", creation_date)
  end

  def self.where_deletion_date_like(deletion_date)
    self.where_date_like("deletion_date", deletion_date)
  end

  def self.where_date_like(field, date)
    return unless field == "deletion_date" || field == "creation_date"
    date_escaped = date.to_s.gsub("_", "\\\\_").gsub("%", "\\\\%")
    search_resuls = CurrentNode.where("#{field}::text LIKE ?", "%#{date_escaped}%")
    search_resuls
  end

  def availability
    availability = false
    response = {}
    accessips = self.accessips
    if accessips.empty?
      response[:errors] = [{
        title: "internal",
        detail: "no-accessips"
      }]
      return response
    else
      if Rails.env.test?
        availability = true
      else
        accessips.each do |accessip|
          http_request = Settings.checker.gsub("{ip}", IPv4::ip(accessip)).gsub("{token}", ENV["CHECKER_TOKEN"])
          http_response = HTTParty.get(http_request)
          availability ||= http_response.parsed_response["data"]["availability"] if http_response.code == 200
          break if availability
        end
      end
    end
    response[:data] = { "availability" => availability }
    response
  end

  def accessips
    accessips = []
    Accessip.where("node_id = ?", self.id).each { |a| accessips.push(IPv4::ip(a.u32)) }
    accessips
  end

  def self.view_order
    {
      :vid => true,
      :info => true,
      :name => true,
      :availability => Settings.iplirconf_api_enabled == "true",
      :ip => Settings.iplirconf_api_enabled == "true",
      :version_decoded => Settings.iplirconf_api_enabled == "true",
      :history => true,
      :creation_date => true,
      :deletion_date => true,
      :ticket => Settings.ticket_api_enabled == "true",
      :search => true,
    }
  end

  def self.info_order
    [
      :network_id,
      :vid,
      :enabled,
      :ip,
      :accessip,
      :version,
      :version_decoded,
      :deletion_date,
      :creation_date,
      :category,
      :ncc,
      :ticket,
    ]
  end
end

class NccNode < ActiveRecord::Base
  belongs_to :network
  has_many :hw_nodes, dependent: :destroy
  has_many :tickets, dependent: :nullify
  has_many :ascendants, dependent: :destroy,
           class_name: "NccNode",
           foreign_key:"descendant_id"
  belongs_to :descendant,
             class_name: "NccNode",
             foreign_key:"descendant_id"
  validates_presence_of :descendant, unless: :type?

  def self.vid_regexp
    /\A0x[0-9a-f]{8}\z/
  end

  validates :vid,
            format: {
              with: NccNode.vid_regexp,
              message: "vid should be like \"#{NccNode.vid_regexp}\"",
            },
            allow_blank: true

  after_create :adopt_tickets

  def self.where_vid_like(vid)
    search_resuls = NccNode.none
    normal_vids = VipnetParser::id(string: vid, threshold: Settings.vid_search_threshold)
    normal_vids.each do |normal_vid|
      search_resuls = search_resuls | NccNode.where("vid = ?", normal_vid)
    end
    search_resuls = search_resuls | NccNode.where("vid ILIKE ?", "%#{vid}%")
    search_resuls
  end

  def self.where_name_like(name)
    name_regexp = name.gsub(" ", ".*")
    search_resuls = NccNode.where("name ~* ?", name_regexp)
    search_resuls
  end

  def self.where_ip_like(ip)
    search_resuls = NccNode.none
    if IPv4::ip?(ip)
      search_resuls = NccNode
        .joins(hw_nodes: :node_ips)
        .where("node_ips.u32 = ?", IPv4::u32(ip))
    end
    if IPv4::cidr(ip) || IPv4::range(ip)
      lower_bound, higher_bound = IPv4::u32_bounds(ip)
      search_resuls = NccNode
        .joins(hw_nodes: :node_ips)
        .where("node_ips.u32 >= ? AND node_ips.u32 <= ?", lower_bound, higher_bound)
    end
    search_resuls
  end

  def self.where_version_decoded_like(version_decoded)
    search_resuls = NccNode.none
    version_decoded_escaped = version_decoded.gsub("_", "\\\\_").gsub("%", "\\\\%")
    search_resuls = NccNode
      .joins(:hw_nodes)
      .where("hw_nodes.version_decoded LIKE ?", "%#{version_decoded_escaped}%")
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
    search_resuls = NccNode.where("#{field}::text LIKE ?", "%#{date_escaped}%")
    search_resuls
  end

  def self.where_ticket_like(ticket_id)
    search_resuls = NccNode
      .joins(:tickets)
      .where("tickets.ticket_id LIKE ?", "%#{ticket_id}%")
    search_resuls
  end

  def self.where_mftp_server_vid_like(mftp_server_vid)
    search_resuls = NccNode.none
    mftp_server = NccNode.find_by(vid: mftp_server_vid, category: "server")
    if mftp_server
      search_resuls = NccNode.where(
        network: mftp_server.network,
        server_number: mftp_server.server_number,
        category: "client",
      )
    end
    search_resuls
  end

  def availability
    availability = false
    response = {}
    accessips = self.accessips
    if accessips.empty?
      return false
    else
      if Rails.env.test?
        availability = true
      else
        sleep(5)
        accessips.each do |accessip|
          http_request = Settings.checker_api
            .gsub("{ip}", accessip)
            .gsub("{token}", ENV["CHECKER_TOKEN"])
          http_response = HTTParty.get(http_request)
          if http_response.code == :ok
            availability ||= http_response.parsed_response["data"]["availability"]
          end
          break if availability
        end
      end
    end
    availability
  end

  def accessips
    accessips = []
    HwNode.where(ncc_node: self).each do |hw_node|
      accessip = hw_node.accessip
      accessips.push(accessip) if accessip
    end
    accessips
  end

  def mftp_server
    if self.category == "client"
      mftp_server = NccNode.find_by(
        network: self.network,
        server_number: self.server_number,
        abonent_number: "0000",
        category: "server",
      )
      mftp_server
    end
  end

  def history(prop)
    if NccNode.props_from_nodename.include?(prop)
      data = self.ascendants
        .order(creation_date: :desc)
        .where("#{prop} IS NOT NULL")
        .as_json(only: [prop, :creation_date])
      return data.map { |slice| slice.symbolize_keys }
    elsif prop == :ip
     elsif HwNode.props_from_iplirconf.include?(prop)
      # group HwNodes' ascendants by days they created (desc)
      # for each group figure out most likely value of prop
      # leave only earliest unique values

      ascendants_ids = self.hw_nodes.map { |hw_node|
        hw_node.ascendants.where("#{prop} IS NOT NULL").ids
      }.flatten
      ascendants = HwNode.where(id: ascendants_ids)

      groups = ascendants
        .order("date_trunc('day', creation_date) DESC")
        .select(:id, :descendant_id, prop, :creation_date)
        .includes(:descendant)
        .group_by(&:creation_date)

      data = groups.map do |creation_date, hw_nodes_array|
        hw_nodes = HwNode.where(id: hw_nodes_array.map(&:id))
        [creation_date, NccNode.most_likely(prop: prop, ncc_node: self, hw_nodes: hw_nodes)]
      end

      data_uniq = data.reject.with_index do |arr, i|
        data[i+1] && arr[1] == data[i+1][1]
      end

      # we lose creation_date precision here, but
      # as long as we show only round days in view, it doesn't matter
      return data_uniq.map do |arr|
         { :creation_date => arr[0], prop => arr[1] }
      end
    end
  end

  def most_likely(prop)
    return NccNode.most_likely(prop: prop, ncc_node: self, hw_nodes: self.hw_nodes)
  end

  def self.most_likely(args)
    # gets most likely value of property (e.g. :version) in set if hw_nodes
    # priorities:
    # 1: hw_node which belongs to ncc_node's mftp_server
    # 2: hw_node which belongs to coordinator with the most registered clients
    # 3: highest count of the same values between hw_nodes
    # 4: hw_node which belongs to coordinator with the lovest vid
    # 5: first hw_node's value

    prop = args[:prop]
    ncc_node = args[:ncc_node]
    hw_nodes = args[:hw_nodes]

    return nil if hw_nodes.empty?

    mftp_server = ncc_node.mftp_server
    if mftp_server
      hw_node_mftp_server = hw_nodes.joins(:coordinator)
        .find_by("coordinators.vid": mftp_server.vid)
      if hw_node_mftp_server
        return hw_node_mftp_server[prop] # 1
      end
    end

    coordinators = {}
    hw_nodes.each do |hw_node|
      coordinator = hw_node.coordinator || hw_node.descendant.coordinator
      coord_vid = coordinator.vid
      clients_registered = NccNode.where_mftp_server_vid_like(coord_vid).count
      coordinators[{
        prop => hw_node[prop],
        vid: coord_vid,
      }] = clients_registered
    end
    # http://stackoverflow.com/a/10695463/6376451
    max_quantity = coordinators.values.max
    max_clients_registered = coordinators.select { |k, v| v == max_quantity }.keys
    if max_clients_registered.size == 1
      return max_clients_registered[0][prop] # 2
    end

    count = hw_nodes.select(prop).group(prop).count
    max_quantity = count.values.max
    max_version = count.select { |k, v| v == max_quantity }.keys
    if max_version.size == 1
      return max_version[0] # 3
    end

    min_coord_vid = coordinators.map { |k,v| k[:vid] }.min
    hw_node_with_min_coord_vid = hw_nodes.joins(:coordinator)
      .find_by("coordinators.vid": min_coord_vid)
    if hw_node_with_min_coord_vid
      return hw_node_with_min_coord_vid[prop] # 4
    end

    hw_nodes.first[prop] # 5
  end

  def self.js_data
    js_data = {}
    all.each do |ncc_node|
      ncc_node = ncc_node.descendant if ncc_node.descendant
      js_data[ncc_node.vid] = ncc_node.as_json(only: [
        :name,
        :creation_date,
        :deletion_date,
        :enabled,
        :category,
        :abonent_number,
        :server_number,
      ])
    end

    js_data
  end

  def to_json_ncc
    json = self.to_json(
      only: NccNode.props_from_nodename + [
        :type,
        :vid,
        :descendant_id,
        :creation_date,
        :creation_date_accuracy,
        :deletion_date,
      ]
    ).gsub("null", "nil")
    json = eval(json)
    tmp = json.clone

    json.each do |key, value|
      if key == :network_id
        network = Network.find_by(id: value)
        tmp[:network_vid] = network.network_vid if network
      elsif key == :descendant_id
        descendant = NccNode.find_by(id: value)
        tmp[:descendant_vid] = descendant.vid if descendant
      end
    end

    tmp.reject! do |key, value|
      key == :descendant_id ||
      value == nil ||
      false
    end

    tmp.to_json
  end

  def self.to_json_ncc
    result = []
    self.all.each do |e|
      result.push(eval(e.to_json_ncc))
    end

    result.to_json.gsub("null", "nil")
  end

  def self.quick_searchable
    [
      :vid, :name,
      :version_decoded, :ip, :creation_date,
      :ticket,
    ]
  end

  def self.props_from_nodename
    [
      :name,
      :enabled,
      :category,
      :abonent_number,
      :server_number,
    ]
  end

  def status
    deleted = self.type == "DeletedNccNode"
    disabled = self.enabled == false
    if deleted
      return :deleted
    elsif disabled
      return :disabled
    else
      return :ok
    end
  end

  private
    def adopt_tickets
      tickets_to_adopt = Ticket.where(vid: self.vid)
      tickets_to_adopt.each do |ticket_to_adopt|
        ticket_to_adopt.update_attribute("ncc_node_id", self.id)
      end
    end
end

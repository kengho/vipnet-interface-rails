class Node < AbstractModel
  belongs_to :network
  validates :network, presence: true

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
    ""
  end

  def self.where_vid_like(vid)
    ""
  end

  def availability
    availability = false
    response = {}
    accessips = self.accessip.values
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
          http_request = Settings.checker.gsub("{ip}", accessip).gsub("{token}", ENV["CHECKER_TOKEN"])
          http_response = HTTParty.get(http_request)
          availability ||= http_response.parsed_response["data"]["availability"] if http_response.code == 200
          break if availability
        end
      end
    end
    response[:data] = { "availability" => availability }
    response
  end

  def info
  end

  def view(param, detalization = :short)
    case param
      when :vid
        self.vid

      when :name
        self.name

      when :network_id
        network = Network.find_by_id(self[param])
        "#{network.network_vid}#{network.name ? ' (' + network.name + ')' : ''}"

      else
        nil
    end
end

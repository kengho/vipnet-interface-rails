class NccNode < ActiveRecord::Base
  belongs_to :network
  has_many :hw_nodes, dependent: :destroy
  has_many :tickets, dependent: :nullify
  has_many :ascendants,
           dependent: :destroy,
           class_name: "NccNode",
           foreign_key: "descendant_id"
  belongs_to :descendant,
             class_name: "NccNode",
             foreign_key: "descendant_id"
  validates :descendant, presence: { unless: :type? }

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

  def self.search(expanded_params)
    search = false

    if expanded_params["search"]
      search = true
      search_resuls = NccNode.none
      search_value = expanded_params["search"]
      NccNode.quick_searchable.each do |search_prop|
        search_resuls |= NccNode.where_prop_like(search_prop, search_value)
      end
    else
      search_resuls = NccNode.all
      expanded_params.each do |prop, value|
        next if prop == "page"

        # FIXME: even wrong params considered as search params.
        search = true
        values = Array(value)
        sub_search_resuls = NccNode.none

        # rubocop:disable Lint/ShadowingOuterLocalVariable
        values.each do |value|
          sub_search_resuls |= NccNode.where_prop_like(prop, value)
        end
        # rubocop:enable Lint/ShadowingOuterLocalVariable

        search_resuls &= sub_search_resuls
      end
    end

    return nil unless search

    search_resuls
  end

  def self.where_prop_like(prop, value)
    case prop
    when "vid"
      vid = value
      search_resuls = NccNode.none
      normal_vids = VipnetParser.id(
        string: vid,
        threshold: Settings.vid_search_threshold,
      )
      normal_vids.each do |normal_vid|
        search_resuls |= NccNode.where("vid = ?", normal_vid)
      end
      search_resuls |= NccNode.where("vid ILIKE ?", "%#{vid}%")

    when "name"
      name = value
      name_regexp = if name =~ /^\"(.*)\"$/
                      Regexp.last_match(1)
                    else
                      name.gsub(" ", ".*")
                    end
      search_resuls = NccNode.where("name ~* ?", name_regexp)
      name_escaped = Regexp.escape(name)
      search_resuls |= NccNode.where("name ILIKE ?", "%#{name_escaped}%")

    when "ip"
      ip = value
      search_resuls = NccNode.none
      if IPv4.ip?(ip)
        search_resuls = NccNode
                          .joins(hw_nodes: :node_ips)
                          .where("node_ips.u32 = ?", IPv4.u32(ip))
      end
      if IPv4.cidr(ip) || IPv4.range(ip)
        lower_bound, higher_bound = IPv4.u32_bounds(ip)
        search_resuls = NccNode
                          .joins(hw_nodes: :node_ips)
                          .where(
                            "node_ips.u32 >= ? AND node_ips.u32 <= ?",
                            lower_bound, higher_bound
                          )
      end

    when "version", "version_decoded"
      version = value
      search_resuls = NccNode.none
      version_escaped = version.gsub("_", "\\\\_").gsub("%", "\\\\%")
      search_resuls = NccNode
                        .joins(:hw_nodes)
                        .where(
                          "hw_nodes.#{prop} LIKE ?",
                          "%#{version_escaped}%",
                        )

    when "creation_date", "deletion_date"
      date = value
      date_escaped = date.to_s.gsub("_", "\\\\_").gsub("%", "\\\\%")
      search_resuls = NccNode.where("#{prop}::text LIKE ?", "%#{date_escaped}%")

    when "ticket"
      ticket_id = value
      search_resuls = NccNode
                        .joins(:tickets)
                        .where("tickets.ticket_id LIKE ?", "%#{ticket_id}%")

    when "mftp_server_vid"
      mftp_server_vid = value
      search_resuls = NccNode.none
      mftp_server = NccNode.find_by(vid: mftp_server_vid, category: "server")
      if mftp_server
        search_resuls = NccNode.where(
          network: mftp_server.network,
          server_number: mftp_server.server_number,
          category: "client",
        )
      end
    end

    search_resuls
  end

  def availability
    accessips = self.accessips
    return false if accessips.empty?
    return true if Rails.env.test?
    if Settings.demo_mode == "true"
      sleep(5)
      return id.even?
    end

    availability = false
    accessips.each do |accessip|
      http_request = Settings
                       .checker_api
                       .sub("{ip}", accessip)
                       .sub("{token}", ENV["CHECKER_TOKEN"])
      http_response = HTTParty.get(http_request)
      if http_response.code == :ok
        availability ||= http_response.parsed_response["data"]["availability"]
      end
      break if availability
    end

    availability
  end

  def accessips
    HwNode
      .where(ncc_node: self)
      .map(&:accessip)
      .reject(&:!)
  end

  def mftp_server
    return unless category == "client"
    mftp_server = NccNode.find_by(
      network: network,
      server_number: server_number,
      abonent_number: "0000",
      category: "server",
    )

    mftp_server
  end

  def history(prop)
    if NccNode.props_from_nodename.include?(prop)
      data = ascendants
               .order(creation_date: :desc)
               .where("#{prop} IS NOT NULL")
               .as_json(only: [prop, :creation_date])

      data.map(&:symbolize_keys)
    elsif prop == :ip
    elsif HwNode.props_from_iplirconf.include?(prop)
      # Algorithm:
      # 1) group HwNodes' ascendants by days they were created (desc),
      # 2) for each group figure out most likely value of prop,
      # 3) leave only earliest unique values.

      ascendants_ids = hw_nodes.flat_map do |hw_node|
        hw_node.ascendants.where("#{prop} IS NOT NULL").ids
      end
      ascendants = HwNode.where(id: ascendants_ids)

      groups = ascendants
                 .order("date_trunc('day', creation_date) DESC")
                 .select(:id, :descendant_id, prop, :creation_date)
                 .includes(:descendant)
                 .group_by(&:creation_date)

      data = groups.map do |creation_date, hw_nodes_array|
        hw_nodes = HwNode.where(id: hw_nodes_array.map(&:id))

        [
          creation_date,
          NccNode.most_likely(
            prop: prop,
            ncc_node: self,
            hw_nodes: hw_nodes,
          ),
        ]
      end

      data_uniq = data.reject.with_index do |arr, i|
        data[i + 1] && arr[1] == data[i + 1][1]
      end

      # We lose creation_date precision here, but,
      # as long as we show only round days in view, it doesn't matter.
      # TODO: find a way to preserve precision.
      data_uniq.map do |arr|
        { :creation_date => arr.first, prop => arr.last }
      end
    end
  end

  def most_likely(prop)
    NccNode.most_likely(
      prop: prop,
      ncc_node: self,
      hw_nodes: hw_nodes,
    )
  end

  def self.most_likely(args)
    # Gets most likely value of property (e.g. "version") in set if "hw_nodes".
    # Values priorities:
    # 1) Value of "hw_node" which belongs to "ncc_node"'s "mftp_server".
    # 2) Value of "hw_node" which belongs to coordinator with the most registered clients.
    # 3) Value which have highest count between all "hw_nodes".
    # 4) Value of "hw_node" which belongs to coordinator with the lovest "vid".
    # 5) First "hw_node"'s value.

    prop, ncc_node, hw_nodes = args.values_at(:prop, :ncc_node, :hw_nodes)
    return nil if hw_nodes.empty?

    mftp_server = ncc_node.mftp_server
    if mftp_server
      hw_node_mftp_server = hw_nodes
                              .joins(:coordinator)
                              .find_by("coordinators.vid" => mftp_server.vid)
      if hw_node_mftp_server
        return hw_node_mftp_server[prop] # priority 1
      end
    end

    coordinators = {}
    hw_nodes.each do |hw_node|
      coordinator = hw_node.coordinator || hw_node.descendant.coordinator
      coord_vid = coordinator.vid
      clients_registered = NccNode
                             .where_prop_like("mftp_server_vid", coord_vid)
                             .count
      coordinator_props = {
        prop => hw_node[prop],
        vid: coord_vid,
      }
      coordinators[coordinator_props] = clients_registered
    end

    # http://stackoverflow.com/a/10695463/6376451
    max_quantity = coordinators.values.max
    max_clients_registered = coordinators
                               .select { |_, v| v == max_quantity }
                               .keys
    if max_clients_registered.size == 1
      return max_clients_registered.first[prop] # priority 2
    end

    count = hw_nodes.select(prop).group(prop).count
    max_quantity = count.values.max
    max_version = count.select { |_, v| v == max_quantity }.keys
    if max_version.size == 1
      return max_version.first # priority 3
    end

    min_coord_vid = coordinators.map { |k, _| k[:vid] }.min
    hw_node_with_min_coord_vid = hw_nodes
                                   .joins(:coordinator)
                                   .find_by("coordinators.vid" => min_coord_vid)

    # priority 4
    return hw_node_with_min_coord_vid[prop] if hw_node_with_min_coord_vid

    hw_nodes.first[prop] # priority 5
  end

  def self.js_data
    js_data = {}
    all.find_each do |ncc_node|
      ncc_node = ncc_node.descendant if ncc_node.descendant
      js_data[ncc_node.vid] = ncc_node.as_json(
        only: %i(
          name
          creation_date
          deletion_date
          enabled
          category
          abonent_number
          server_number
        ),
      )
    end

    js_data
  end

  def to_json_ncc
    json = to_json(
      only: NccNode.props_from_nodename +
        %i(
          type
          vid
          descendant_id
          creation_date
          creation_date_accuracy
          deletion_date
          network_id
        ),
    ).gsub("null", "nil")
    json = eval(json)
    tmp = json.clone

    json.each do |key, value|
      if key == :network_id
        network = Network.find_by(id: value)

        # "network" may not exist, if "ncc_node" is an accendant.
        tmp[:network_vid] = network.network_vid if network
      elsif key == :descendant_id
        descendant = NccNode.find_by(id: value)
        tmp[:descendant_vid] = descendant.vid if descendant
      end
    end

    tmp.reject! do |key, value|
      key == :descendant_id ||
        key == :network_id ||
        value.nil?
    end

    tmp.to_json
  end

  def self.to_json_ncc
    all
      .map { |e| eval(e.to_json_ncc) }
      .to_json.gsub("null", "nil")
  end

  def self.vids
    all.map(&:vid).reject(&:!).sort
  end

  def self.quick_searchable
    %w(vid name version_decoded ip creation_date ticket)
  end

  def self.props_from_nodename
    %i(
      name
      enabled
      category
      abonent_number
      server_number
    )
  end

  def status
    return :deleted if type == "DeletedNccNode"
    return :disabled unless enabled

    :ok
  end

  private

    def adopt_tickets
      tickets_to_adopt = Ticket.where(vid: vid)
      tickets_to_adopt.each do |ticket_to_adopt|
        ticket_to_adopt.update_attributes(ncc_node_id: id)
      end
    end
end

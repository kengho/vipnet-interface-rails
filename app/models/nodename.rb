class Nodename < ActiveRecord::Base
  belongs_to :network
  validates :network_id,  presence: true,
                          uniqueness: true

  def read_content(content, vipnet_network_id)
    self.content = Hash.new
    record_regexp = /^
      (?<name>.{50})\s
      (?<enabled>[01])\s
      (?<category>[ASG])\s
      [0-9A-F]{8}
      (?<server_number>[0-9A-F]{4})
      (?<abonent_number>[0-9A-F]{4})\s
      (?<vipnet_id>[0-9A-F]{8})
    $/x
    # (...{50}) 1 A 00001A0E000100D3 1A0E1111
    networks_to_ignore = Settings.networks_to_ignore.split(",")
    lines = content.split("\r\n")
    if lines.size == 0
      Rails.logger.error("Error parsing nodename")
      return false
    end
    lines.each do |line|
      match = record_regexp.match(line)
      if match
        tmp_record = Hash.new
        tmp_record["vipnet_id"] = Node.normalize_vipnet_id(match["vipnet_id"])
        tmp_record["vipnet_network_id"] = Node.network(tmp_record["vipnet_id"])
        tmp_record["category"] = Node.categories[match["category"]]
        # drop groups
        next if tmp_record["category"] == "group"
        # drop ignored networks
        next if networks_to_ignore.include?(tmp_record["vipnet_network_id"])
        # drop nodes in networks we admin, that also are internetworking nodes
        # (networks we admin - networks, for which we have nodenames)
        next if ( Nodename.joins(:network).where("vipnet_network_id = ?", tmp_record["vipnet_network_id"]).size > 0 &&
                  tmp_record["vipnet_network_id"] != vipnet_network_id )
        # tmp_record["content"] = line
        tmp_record["name"] = match["name"].rstrip
        tmp_record["enabled"] = match["enabled"] == "1" ? true : false
        tmp_record["server_number"] = match["server_number"]
        tmp_record["abonent_number"] = match["abonent_number"]
        self.content[line] = tmp_record
      else
        Rails.logger.error("Error parsing line '#{line}'")
        return false
      end
    end
    network = Network.find_or_create_network(vipnet_network_id)
    self.network_id = network.id
    true
  end
end

class Iplirconf < ActiveRecord::Base
  belongs_to :coordinator
  validates :coordinator_id, presence: true

  def parse
    # remove comments
    self.content.gsub!(/^#.*\n/, "")
    # remove trash in the end
    self.sections = Hash.new
    adapter_position = self.content.index("[adapter]")
    unless adapter_position
      Rails.logger.error("Unable to parse iplirconf (no [adapter] section)")
      return false
    end
    self.content = self.content[0..(adapter_position - 2)] if adapter_position
    self.content = "\n" + self.content
    self.content.split("\n[id]\n").reject{ |t| t.empty? }.each_with_index do |section_content, i|
      tmp_section = Hash.new
      tmp_section["vipnet_id"] = section_content[/id=\s(?<vipnet_id>.{10})/, "vipnet_id"]
      tmp_section["name"] = section_content[/name=\s(?<name>.*$)/, "name"]
      tmp_section["ips"] = Array.new
      section_content.each_line do |line|
        match = line[/^ip=\s(?<ip>.*)/, "ip"]
        tmp_section["ips"].push(match.to_s) if match
      end
      tmp_section["accessip"] = section_content[/accessip=\s(?<accessip>[0-9\.]*)/, "accessip"]
      tmp_section["vipnet_version"] = section_content[/version=\s(?<version>[0-9\.-]*)/, "version"]
      # drop "Encrypted broadcasts" and "Main Filter" sections
      unless (tmp_section["vipnet_id"] == "0xffffffff" || tmp_section["vipnet_id"] == "0xfffffffe")
        # yaml doesn't contains object id
        # object: <MessagesController::Test:0x0000000780a140 @q="q">
        # yaml: "--- !ruby/object:MessagesController::Test\nq: q\n"
        # this allows to search for new keys via hash.key?
        self.sections["self"] = tmp_section if i == 0
        self.sections[tmp_section.to_yaml] = tmp_section
      end
    end
    true
  end

end

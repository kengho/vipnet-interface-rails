class Node < ActiveRecord::Base
  belongs_to :network
  validates :vipnet_id, presence: true,
                        format: { with: /\A0x[0-9a-f]{8}\z/, message: "vipnet_id should be like \"0x1a0e0100\"" }
  validates :network_id, presence: true
  validates :name, presence: true
  default_scope { order(created_at: :desc) }

  def self.searchable
    searchable = {
      "vipnet_id" => "vipnet_id",
      "name" => "name",
      "ips" => { "ips" => "summary" },
      "vipnet_version" => { "vipnet_version" => "summary" },
      "deleted_at" => "deleted_at::text",
      "created_first_at" => "created_first_at::text"
    }
  end

  def self.vipnet_versions_substitute(str)
    substitution_list = {
      /^$/ => "",
      /^3\.0\-.*/ => "3.1",
      /^3\.2\-.*/ => "3.2",
      /^0\.3\-2$/ => "3.2 (11.19855)",
      /^4\..*/ => "4",
    }
    regexps = Array.new
    substitution_list.each do |search_regexp, view|
      return view if str =~ search_regexp
      regexps.push(search_regexp) if view =~ Regexp.new(Regexp.escape(str))
    end
    return regexps unless regexps.empty?
    ""
  end

  def self.pg_regexp_adoptation(pg_regexp)
    substitution_list = {
      "_" => "\\_",
      "\.\*" => "%",
      "\\-" => "-",
      "\\." => "DOT",
      "\." => "_",
      "DOT" => ".",
    }
    # pg_regexp = regexp.source
    if pg_regexp[0] == "^"
      pg_regexp = pg_regexp[1..-1]
    else
      pg_regexp = "%#{pg_regexp}"
    end
    if pg_regexp[-1] == "$"
      pg_regexp = pg_regexp[0..-2]
    else
      pg_regexp = "#{pg_regexp}%"
    end
    substitution_list.each do |ruby_regexp_pattern, pg_regexp_pattern|
      pg_regexp = pg_regexp.gsub(ruby_regexp_pattern, pg_regexp_pattern)
    end
    return pg_regexp
  end

  def self.categories
    categories = { "A" => "client", "S" => "server", "G" => "group" }
  end

  def self.normalize_vipnet_id(vipnet_id)
    # 0123ABCD
    if vipnet_id =~ /[0-9A-F]{8}/
      return "0x" + vipnet_id.downcase
    end
    false
  end

  def self.network(vipnet_id)
    # 0x|0123|abcd
    if vipnet_id =~ /0x[0-9a-f]{8}/
      return vipnet_id[2..5].to_i(16).to_s(10)
    end
    false
  end

  def accessips(output = Array)
    if output == Array
      accessips = Array.new
      Iplirconf.all.each do |iplirconf|
        iplirconf.sections.each do |_, section|
          accessips.push(eval(section)["accessip"]) if eval(section)["vipnet_id"] == self.vipnet_id
        end
      end
      accessips.reject!{ |a| a.nil? }
    elsif output == Hash
      accessips = Hash.new
      Iplirconf.all.each do |iplirconf|
        if iplirconf.sections["self"]
          coordinator_vipnet_id = eval(iplirconf.sections["self"])["vipnet_id"]
          iplirconf.sections.each do |_, section|
            accessips[coordinator_vipnet_id] = eval(section)["accessip"] if eval(section)["vipnet_id"] == self.vipnet_id
          end
        end
      end
    end
    accessips.reject { |a| a == "0.0.0.0" }
  end

  def availability
    require "httparty"
    availability = false
    response = Hash.new
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
          http_request = Settings.checker.gsub("#\{ip}", accessip).gsub("#\{token}", ENV["CHECKER_TOKEN"])
          http_response = HTTParty.get(http_request)
          availability ||= http_response.parsed_response["data"]["availability"] if http_response.code == 200
          break if availability
        end
      end
    end
    response[:data] = { availability: availability }
    response
  end

  def ips_summary
    ips_summary = Array.new
    self.ips.each do |_, ips_array|
      # before saving ips_array is Array, after saving it's String
      if ips_array =~ /\[.*\]/
        ips_array_eval = eval(ips_array)
        ips_summary += ips_array_eval if ips_array_eval.class == Array
      elsif ips_array.class == Array
        ips_summary += ips_array
      end
    end
    ips_summary = ips_summary.uniq.join(", ")
    ips_summary
  end

  def vipnet_version_summary
    vipnet_versions = Array.new
    self.vipnet_version.each do |key, vipnet_version|
      if !vipnet_version.nil? && key != "summary"
        vipnet_versions.push(vipnet_version) unless vipnet_version.nil?
      end
    end
    uniq_vipnet_versions = vipnet_versions.uniq
    return "" if uniq_vipnet_versions.size == 0
    return uniq_vipnet_versions[0] if uniq_vipnet_versions.size == 1
    return "?" if uniq_vipnet_versions.size > 1
  end

  def mftp_server
    return false if self.category == "server"
    return nil unless self.server_number && self.abonent_number
    mftp_servers = Node.where(
      "category = 'server' AND "\
      "server_number = ? AND "\
      "network_id = ? AND "\
      "history = 'false'"\
      "",
      self.server_number,
      self.network_id)
    return mftp_servers.first if mftp_servers.size == 1
    if mftp_servers.size == 0
      Rails.logger.error("No mftp servers found '#{self.id}'")
      return nil
    elsif mftp_servers.size == 1
      return mftp_servers.first
    elsif mftp_servers.size > 0
      Rails.logger.error("Multiple mftp servers found '#{self.id}'")
      return nil
    end
  end

  def self.update_all
    Nodename.all.each do |nodename|
      nodename.content.each do |_, record|
        nodes = Node.where("vipnet_id = ? AND history = 'false'", eval(record)["vipnet_id"])
        if nodes.size == 1
          node = nodes.first
          Nodename.fields_from_record.each { |field| node[field] = eval(record)[field] }
          node.save!
        end
      end
    end
    Iplirconf.all.each do |iplirconf|
      coordinator_vipnet_id = eval(iplirconf.sections["self"])["vipnet_id"]
      iplirconf.sections.each do |key, section|
        next if key == "self"
        nodes = Node.where("vipnet_id = ? AND history = 'false'", eval(section)["vipnet_id"])
        if nodes.size == 1
          node = nodes.first
          Iplirconf.fields_from_section.each { |field| node[field][coordinator_vipnet_id] = eval(section)[field] }
          Iplirconf.fields_from_section.each do |field|
            # http://stackoverflow.com/a/5349874
            method_name = "#{field}_summary"
            node[field]["summary"] = node.public_send(method_name) if node.respond_to?(method_name)
          end
          node.save!
        end
      end
    end
  end

end

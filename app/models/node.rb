class Node < ActiveRecord::Base
  belongs_to :network
  validates :vipnet_id, presence: true,
                        format: { with: /\A0x[0-9a-f]{8}\z/, message: "vipnet_id should be like \"0x1a0e0100\"" }
  validates_uniqueness_of :vipnet_id, scope: :history, conditions: -> { where(history: false) }
  validates :network_id, presence: true
  validates :name, presence: true

  def self.searchable
    searchable = {
      "vipnet_id" => "vipnet_id",
      "name" => "name",
      "ip" => { "ip" => "summary" },
      "version" => { "version" => "summary" },
      "deleted_at" => "deleted_at::text",
      "created_first_at" => "created_first_at::text",
      "ticket_id" => { "tickets" => "ids_summary" },
      "server_number" => "server_number",
      "category" => "category",
      "history" => "history::text",
      "network_id" => "network_id",
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

  def accessips(output = Array)
    if output == Array
      accessips = Array.new
      Iplirconf.all.each do |iplirconf|
        iplirconf.sections.each do |vipnet_id, section|
          accessips.push(eval(section)[:accessip]) if vipnet_id == self.vipnet_id
        end
      end
      accessips.reject! { |a| a.nil? || a == "0.0.0.0" }
      accessips.sort! if accessips
    elsif output == Hash
      accessips = Hash.new
      Iplirconf.all.each do |iplirconf|
        coordinator = Coordinator.find_by_id(iplirconf.coordinator_id)
        coordinator_vipnet_id = coordinator.vipnet_id
        iplirconf.sections.each do |vipnet_id, section|
          accessips[coordinator_vipnet_id] = eval(section)[:accessip] if vipnet_id == self.vipnet_id
        end
      end
    end
    accessips
  end

  def availability
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

  def ip_summary
    ip_summary = Array.new
    self.ip.each do |_, ip_array|
      # before saving ips_array is Array, after saving it's String
      if ip_array =~ /\[.*\]/
        ip_array_eval = eval(ip_array)
        ip_summary += ip_array_eval if ip_array_eval.class == Array
      elsif ip_array.class == Array
        ip_summary += ip_array
      end
    end
    ip_summary = ip_summary.uniq.join(", ")
    ip_summary
  end

  def version_summary
    version_summary = Array.new
    self.version.each do |key, version|
      if !version.nil? && key != "summary"
        version_summary.push(version) unless version.nil?
      end
    end
    uniq_version = version_summary.uniq
    return "" if uniq_version.size == 0
    return uniq_version[0] if uniq_version.size == 1
    return "?" if uniq_version.size > 1
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
    Node.record_timestamps = false
    Nodename.all.each do |nodename|
      nodename.records.each do |vipnet_id, record|
        record = eval(record)
        node = Node.find_by(vipnet_id: vipnet_id, history: false)
        if node
          Nodename.props_from_record.each do |prop_name|
            node[prop_name] = record[prop_name] if record[prop_name]
          end
          node.save!
        end
      end
    end
    Iplirconf.all.each do |iplirconf|
      coordinator = Coordinator.find_by_id(iplirconf.coordinator_id)
      coordinator_vipnet_id = coordinator.vipnet_id
      iplirconf.sections.each do |vipnet_id, section|
        node = Node.find_by(vipnet_id: vipnet_id, history: false)
        if node
          Iplirconf.props_from_section.each { |prop_name| node[prop_name][coordinator_vipnet_id] = eval(section)[prop_name] }
          Iplirconf.props_from_section.each do |prop_name|
            # http://stackoverflow.com/a/5349874
            method_name = "#{prop_name}_summary"
            node[prop_name]["summary"] = node.public_send(method_name) if node.respond_to?(method_name)
          end
          node.save!
        end
      end
    end
    Node.record_timestamps = true
  end

  # WARNING! UNTESTED!
  def self.fix_created_first_at_accuracy
    Node.record_timestamps = false
    nodes_no_history = Node.where("history = 'false'")
    nodes_no_history.each do |node_no_history|
      vipnet_id = node_no_history.vipnet_id
      nodes = Node.where("vipnet_id = ?", vipnet_id).reorder(created_at: :asc)
      created_first_at_accuracy_first = nodes.first.created_first_at_accuracy
      created_first_at_accuracy_last = nodes.last.created_first_at_accuracy
      unless created_first_at_accuracy_first == created_first_at_accuracy_last
        nodes.each do |node|
          node.created_first_at_accuracy = created_first_at_accuracy_first
          node.save!
        end
      end
    end
    Node.record_timestamps = true
  end

  def data_js
    return ""\
      "vipnetId: '#{self.vipnet_id}',"\
      "name: '#{self.name}',"\
      "enabled: '#{self.enabled}',"\
      "history: '#{self.history}',"\
      "category: '#{self.category}',"\
      "ip: '#{self.ip["summary"]}',"\
      "createdAt: '#{self.created_first_at}',"\
      "deletedAt: '#{self.deleted_at}',"\
      "abonentNumber: '#{self.abonent_number}',"\
      "serverNumber: '#{self.server_number}',"\
      "tickets: '#{self.tickets["ids_summary"]}',"\
      ""
  end

  def testable?
    !self.history && self.enabled && !self.deleted_at
  end

  def self.clean
    # remove nodes from ignoring networks
    Settings.networks_to_ignore.split(",").each do |network_to_ignore|
      network = Network.find_by(vipnet_network_id: network_to_ignore)
      Node.where("network_id = ?", network.id).destroy_all if network
    end

    # delete duplicates
    # break nodes by vipnet_id, sort by id
    # move from first to last
    # if nothing important changes (including empty summary in "ip" and "version"), delete node
    # if changes, make it current and compare next
    important_props = Nodename.props_from_record + Iplirconf.props_from_section + [:deleted_at]
    nodes = Node.all.order(vipnet_id: :asc).order(id: :desc)
    current_node = nodes.first
    nodes.each do |node|
      next if node == nodes.first
      if node.vipnet_id != current_node.vipnet_id
        current_node = node
        next
      end
      it_differs = false
      important_props.each do |prop|
        [node, current_node].each do |node|
          if node[prop].class == Hash
            node[prop] = Hash.new if node[prop]["summary"] == ""
          end
        end
        if node[prop] != current_node[prop]
          it_differs = true
          break
        end
      end
      if it_differs
        current_node = node
      else
        node.destroy
      end
    end
  end
end

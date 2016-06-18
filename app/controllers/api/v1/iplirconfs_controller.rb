class Api::V1::IplirconfsController < Api::V1::BaseController
  def create
    unless (params[:content] && params[:vipnet_id])
      Rails.logger.error("Incorrect params")
      render plain: "error" and return
    end

    uploaded_file = params[:content].tempfile
    coordinator_vipnet_id = params[:vipnet_id]
    uploaded_file_content = File.read(uploaded_file).force_encoding("cp866").encode("utf-8", replace: nil)

    new_iplirconf = Iplirconf.new
    parsed_iplirconf = VipnetParser::Iplirconf.new({ content: uploaded_file_content, arrays_to_s: true })
    render plain: "error" and return unless parsed_iplirconf
    new_iplirconf.sections = parsed_iplirconf.sections

    coordinators = Coordinator.where("vipnet_id = ?", coordinator_vipnet_id)
    if coordinators.size == 0
      name = eval(new_iplirconf.sections[coordinator_vipnet_id])[:name]
      coordinator_vipnet_network_id = VipnetParser::network(coordinator_vipnet_id)
      coordinator_network = Network.find_or_create_by(vipnet_network_id: coordinator_vipnet_network_id)
      render plain: "error" and return unless coordinator_network
      coordinator = Coordinator.new(vipnet_id: coordinator_vipnet_id, name: name, network_id: coordinator_network.id)
      render plain: "error" and return unless coordinator.save!
    elsif coordinators.size == 1
      coordinator = coordinators.first
    elsif coordinators.size > 1
      Rails.logger.error("More than one coordinator found '#{coordinator_vipnet_id}'")
      render plain: "error" and return
    end
    new_iplirconf.coordinator_id = coordinator.id

    existing_iplirconfs = Iplirconf.where("coordinator_id = ?", new_iplirconf.coordinator_id)
    if existing_iplirconfs.size == 0
      # for cmp
      existing_iplirconf = Iplirconf.new
      existing_iplirconf.coordinator_id = new_iplirconf.coordinator_id
    elsif existing_iplirconfs.size == 1
      existing_iplirconf = existing_iplirconfs.first
    elsif existing_iplirconfs.size > 1
      Rails.logger.error("More than one iplirconfs found '#{new_iplirconf.coordinator_id}'")
      render plain: "error" and return
    end

    changed_sections = existing_iplirconf.changed_sections(new_iplirconf)
    changed_sections.each do |vipnet_id, section|
      something_important_changed = false
      Iplirconf.props_from_section.each do |prop_name|
        if section[prop_name]
          something_important_changed = true
          break
        end
      end
      next unless something_important_changed
      nodes_to_history = Node.where("vipnet_id = ? AND history = 'false'", vipnet_id)
      if nodes_to_history.size == 0
        Rails.logger.error("Unable to find nodes_to_history '#{vipnet_id}',"\
          "coordinator_vipnet_id '#{new_iplirconf.coordinator_id}'")
        next
      elsif nodes_to_history.size == 1
        node_to_history = nodes_to_history.first
        node = node_to_history.dup
        node_to_history.history = true
        node_to_history.save!
        Iplirconf.props_from_section.each do |prop_name|
          node[prop_name][coordinator_vipnet_id] = section[prop_name] if section.key?(prop_name)
          method_name = "#{prop_name.to_sym}_summary"
          node[prop_name]["summary"] = node.public_send(method_name) if node.respond_to?(method_name)
        end
        node.save!
      elsif nodes_to_history.size > 1
        Rails.logger.error("More than one non-history nodes found '#{vipnet_id}'")
        render plain: "error" and return
      end
    end

    existing_iplirconf.sections = new_iplirconf.sections
    existing_iplirconf.content = new_iplirconf.content
    existing_iplirconf.save!
    render plain: "ok"
  end
end

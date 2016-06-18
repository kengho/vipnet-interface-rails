class Api::V1::IplirconfsController < Api::V1::BaseController
  def create
    unless (params[:content] && params[:vipnet_id])
      Rails.logger.error("Incorrect params #{params}")
      render plain: ERROR_RESPONSE and return
    end

    uploaded_file = params[:content].tempfile
    coordinator_vipnet_id = params[:vipnet_id]
    uploaded_file_content = File.read(uploaded_file).force_encoding("cp866").encode("utf-8", replace: nil)

    new_iplirconf = Iplirconf.new
    parsed_iplirconf = VipnetParser::Iplirconf.new({ content: uploaded_file_content, arrays_to_s: true })
    render plain: ERROR_RESPONSE and return unless parsed_iplirconf
    new_iplirconf.sections = parsed_iplirconf.sections

    coordinator = Coordinator.find_by(vipnet_id: coordinator_vipnet_id)
    unless coordinator
      name = eval(new_iplirconf.sections[coordinator_vipnet_id])[:name]
      coordinator_vipnet_network_id = VipnetParser::network(coordinator_vipnet_id)
      coordinator_network = Network.find_or_create_by(vipnet_network_id: coordinator_vipnet_network_id)
      render plain: ERROR_RESPONSE and return unless coordinator_network
      coordinator = Coordinator.new(vipnet_id: coordinator_vipnet_id, name: name, network_id: coordinator_network.id)
      render plain: ERROR_RESPONSE and return unless coordinator.save!
    end
    new_iplirconf.coordinator_id = coordinator.id

    existing_iplirconf = Iplirconf.find_by(coordinator_id: new_iplirconf.coordinator_id)
    unless existing_iplirconf
      # for cmp
      existing_iplirconf = Iplirconf.new
      existing_iplirconf.coordinator_id = new_iplirconf.coordinator_id
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
      node_to_history = Node.find_by(vipnet_id: vipnet_id, history: false)
      if node_to_history
        node = node_to_history.dup
        node_to_history.history = true
        node_to_history.save!
        Iplirconf.props_from_section.each do |prop_name|
          node[prop_name][coordinator_vipnet_id] = section[prop_name] if section.key?(prop_name)
          method_name = "#{prop_name.to_sym}_summary"
          node[prop_name]["summary"] = node.public_send(method_name) if node.respond_to?(method_name)
        end
        node.save!
      else
        next
      end
    end

    existing_iplirconf.sections = new_iplirconf.sections
    existing_iplirconf.content = new_iplirconf.content
    existing_iplirconf.save!
    render plain: OK_RESPONSE and return
  end
end

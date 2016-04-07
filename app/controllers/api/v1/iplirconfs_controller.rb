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
    new_iplirconf.content = uploaded_file_content
    unless new_iplirconf.parse
      # error logged in iplirconf.rb
      render plain: "error" and return
    end
    coordinators = Coordinator.where("vipnet_id = ?", coordinator_vipnet_id)
    if coordinators.size == 0
      name = new_iplirconf.sections["self"]["name"]
      coordinator_vipnet_network_id = Node.network(coordinator_vipnet_id)
      coordinator_network = Network.find_or_create_network(coordinator_vipnet_network_id)
      unless coordinator_network
        render plain: "error" and return
      end
      coordinator = Coordinator.new(vipnet_id: coordinator_vipnet_id, name: name, network_id: coordinator_network.id)
      unless coordinator.save
        Rails.logger.error("Unable to save coordinator '#{coordinator_vipnet_id}'")
        render plain: "error" and return
      end
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
      existing_iplirconf.sections = Hash.new
      existing_iplirconf.coordinator_id = new_iplirconf.coordinator_id
    elsif existing_iplirconfs.size == 1
      existing_iplirconf = existing_iplirconfs.first
    elsif existing_iplirconfs.size > 1
      Rails.logger.error("More than one iplirconfs found '#{new_iplirconf.coordinator_id}'")
      render plain: "error" and return
    end

    new_iplirconf.sections.each do |key, section|
      # http://stackoverflow.com/questions/15265328/finding-differences-between-two-files-in-rails
      next if existing_iplirconf.sections.key?(key)
      existing_nodes = Node.where("vipnet_id = ? AND history = 'false'", section['vipnet_id'])
      if existing_nodes.size == 0
        Rails.logger.error("Unable to find existing_nodes '#{section['vipnet_id']}',"\
          "coordinator_vipnet_id '#{new_iplirconf.coordinator_id}'")
        next
      end
      existing_node = existing_nodes.first
      new_node = Node.new do |n|
        n.vipnet_id = existing_node.vipnet_id
        n.network_id = existing_node.network_id
        n.name = existing_node.name
        n.enabled = existing_node.enabled
        n.created_first_at = existing_node.created_first_at
        n.created_by_message_id = existing_node.created_by_message_id
        n.deleted_by_message_id = existing_node.deleted_by_message_id
        n.ips[coordinator_vipnet_id] = section["ips"]
        n.vipnet_version[coordinator_vipnet_id] = section["vipnet_version"]
      end
      new_node.ips["summary"] = new_node.ips_summary
      new_node.vipnet_version["summary"] = new_node.vipnet_versions_summary
      unless new_node.save
        Rails.logger.error("Unable to save new_node '#{new_node.vipnet_id}'")
        render plain: "error" and return
      end
      existing_node.history = true
      unless existing_node.save
        Rails.logger.error("Unable to save existing_node '#{existing_node.vipnet_id}'")
        render plain: "error" and return
      end
    end

    existing_iplirconf.sections = new_iplirconf.sections
    existing_iplirconf.content = new_iplirconf.content
    unless existing_iplirconf.save
      Rails.logger.error("Unable to save existing_iplirconf")
      render plain: "error" and return
    end

    render plain: "ok"
  end

end

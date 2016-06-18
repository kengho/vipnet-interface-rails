class Api::V1::NodenamesController < Api::V1::BaseController
  def create
    unless (params[:content] && params[:vipnet_network_id])
      Rails.logger.error("Incorrect params #{params}")
      render plain: ERROR_RESPONSE and return
    end

    uploaded_file = params[:content].tempfile
    nodename_vipnet_network_id = params[:vipnet_network_id]
    uploaded_file_content = File.read(uploaded_file)
    new_nodename = Nodename.new
    parsed_nodename = VipnetParser::Nodename.new(uploaded_file_content)
    render plain: ERROR_RESPONSE and return unless parsed_nodename
    new_nodename.records = parsed_nodename.records
    existing_nodename = Nodename.joins(:network).find_by("networks.vipnet_network_id": nodename_vipnet_network_id)
    new_records = Hash.new
    if existing_nodename
      created_first_at_accuracy = true
    else
      created_first_at_accuracy = false
      network = Network.find_or_create_by(vipnet_network_id: nodename_vipnet_network_id)
      render plain: ERROR_RESPONSE and return unless network
      existing_nodename = Nodename.new(network_id: network.id)
      existing_nodename.records = Hash.new
      # clean existing nodes which belongs to incoming nodename's networks
      nodes_to_destroy = Node.joins(:network).where("networks.id = ?", existing_nodename.network_id)
      nodes_to_destroy.destroy_all
    end

    changed_records = existing_nodename.changed_records(new_nodename)
    networks_to_ignore = Settings.networks_to_ignore.split(",")
    changed_records.each do |vipnet_id, record|
      if existing_nodename.records[vipnet_id]
        next if eval(existing_nodename.records[vipnet_id])[:category] == :group
      elsif record[:category]
        next if record[:category] == :group
      end
      record_vipnet_network_id = VipnetParser::network(vipnet_id)
      network = Network.find_or_create_by(vipnet_network_id: record_vipnet_network_id)
      render plain: ERROR_RESPONSE and return unless network
      we_admin_this_network = Nodename.joins(:network).where("vipnet_network_id = ?", record_vipnet_network_id).size > 0
      it_is_internetworking_node = nodename_vipnet_network_id != record_vipnet_network_id
      next if we_admin_this_network && it_is_internetworking_node
      next if networks_to_ignore.include?(network.vipnet_network_id)
      node_to_history = Node.find_by(vipnet_id: vipnet_id, history: false)
      if node_to_history
        node = node_to_history.dup
        node_to_history.history = true
        node_to_history.save!
      else
        node = Node.new(created_first_at: DateTime.now)
      end
      Nodename.props_from_record.each do |prop_name|
        node[prop_name] = record[prop_name] if record.key?(prop_name)
      end
      node.vipnet_id = vipnet_id
      node.network_id = network.id
      node.created_first_at_accuracy = created_first_at_accuracy
      node.save!
    end

    # rewrite nodename
    existing_nodename.records = new_nodename.records
    existing_nodename.save!
    render plain: OK_RESPONSE and return
  end
end

class Api::V1::NodenamesController < Api::V1::BaseController

  def create
    unless (params[:content] && params[:vipnet_network_id])
      Rails.logger.error("Incorrect params")
      render plain: "error" and return
    end

    uploaded_file = params[:content].tempfile
    vipnet_network_id = params[:vipnet_network_id]
    uploaded_file_content = File.read(uploaded_file).force_encoding("cp866").encode("utf-8", replace: nil)

    new_nodename = Nodename.new
    response = new_nodename.read_content(uploaded_file_content, vipnet_network_id)
    unless response
      # error logged in nodename.rb
      render plain: "error" and return
    end

    existing_nodenames = Nodename.joins(:network).where("networks.vipnet_network_id = ?", vipnet_network_id)
    new_records = Hash.new
    if existing_nodenames.size == 0
      created_first_at_accuracy = false
      existing_nodename = Nodename.new
      existing_nodename.content = Hash.new
      network = Network.find_or_create_network(vipnet_network_id)
      unless network
        # error logged in find_or_create_network
        render plain: "error" and return
      end
      existing_nodename.network_id = network.id
      # clean existing nodes in incoming nodename's networks
      nodes_to_destroy = Node.joins(:network).where("networks.id = ?", existing_nodename.network_id)
      nodes_to_destroy.destroy_all
    elsif existing_nodenames.size == 1
      existing_nodename = existing_nodenames.first
    elsif existing_nodenames.size > 1
      Rails.logger.error("More than one nodename found '#{vipnet_network_id}'")
      render plain: "error" and return
    end
    new_nodename.content.each do |key, record|
      # http://stackoverflow.com/questions/15265328/finding-differences-between-two-files-in-rails
      next if existing_nodename.content.key?(key)
      network = Network.find_or_create_network(record['vipnet_network_id'])
      unless network
        render plain: "error" and return
      end

      node = Node.new do |n|
        n.vipnet_id = record["vipnet_id"]
        n.network_id = network.id
        n.name = record["name"]
        n.enabled = record["enabled"]
        n.category = record["category"]
        n.created_first_at_accuracy = created_first_at_accuracy if defined?(created_first_at_accuracy)
      end
      # set "created_first_at" and other fields for new node, update "history" for old nodes
      nodes_to_history = Node.where("vipnet_id = ? AND history = 'false'", node.vipnet_id)
      if nodes_to_history.size == 0
        node.created_first_at = DateTime.now
        unless node.save
          Rails.logger.error("Unable to save node '#{node.vipnet_id}' (1)")
          render plain: "error" and return
        end
      elsif nodes_to_history.size == 1
        node_to_history = nodes_to_history.first
        node.created_first_at = node_to_history.created_first_at
        # just in case
        node.deleted_by_message_id = node_to_history.deleted_by_message_id
        node.deleted_at = node_to_history.deleted_at
        #
        node.created_by_message_id = node_to_history.created_by_message_id
        node.ips = node_to_history.ips
        node.vipnet_version = node_to_history.vipnet_version

        node_to_history.history = true
        unless node.save
          Rails.logger.error("Unable to save node '#{node.vipnet_id}' (2)")
          render plain: "error" and return
        end
        unless node_to_history.save
          Rails.logger.error("Unable to save node_to_history '#{node_to_history.id}'")
          render plain: "error" and return
        end
      elsif nodes_to_history.size > 1
        Rails.logger.error("More than one non-history nodes found '#{node.vipnet_id}'")
        render plain: "error" and return
      end
    end

    existing_nodename.content = new_nodename.content
    unless existing_nodename.save
      Rails.logger.error("Unable to save existing_nodename")
      render plain: "error" and return
    end

    render plain: "ok"
  end

end

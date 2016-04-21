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
    render plain: "error" and return unless response
    existing_nodenames = Nodename.joins(:network).where("networks.vipnet_network_id = ?", vipnet_network_id)
    new_records = Hash.new
    created_first_at_accuracy = true
    if existing_nodenames.size == 0
      created_first_at_accuracy = false
      existing_nodename = Nodename.new
      existing_nodename.content = Hash.new
      network = Network.find_or_create_network(vipnet_network_id)
      # error logged in find_or_create_network
      render plain: "error" and return unless network
      existing_nodename.network_id = network.id
      # clean existing nodes which belongs to incoming nodename's networks
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
      network = Network.find_or_create_network(record["vipnet_network_id"])
      render plain: "error" and return unless network
      nodes_to_history = Node.where("vipnet_id = ? AND history = 'false'", record["vipnet_id"])
      if nodes_to_history.size == 0
        node = Node.new
        node.created_first_at = DateTime.now
      elsif nodes_to_history.size == 1
        node_to_history = nodes_to_history.first
        node = node_to_history.dup
        node_to_history.history = true
        node_to_history.save!
      elsif nodes_to_history.size > 1
        Rails.logger.error("More than one non-history nodes found '#{record["vipnet_id"]}'")
        render plain: "error" and return
      end
      fields_from_record = ["vipnet_id", "name", "enabled", "category", "abonent_number", "server_number"]
      fields_from_record.each { |field| node[field] = record[field] }
      node.network_id = network.id
      node.created_first_at_accuracy = created_first_at_accuracy
      node.save!
    end

    existing_nodename.content = new_nodename.content
    existing_nodename.save!
    render plain: "ok"
  end

end

class Api::V1::NodenamesController < Api::V1::BaseController
  def create
    unless (params[:file] && params[:network_vid])
      Rails.logger.error("Incorrect params #{params}")
      render plain: ERROR_RESPONSE and return
    end

    file_content = File.read(params[:file].tempfile)
    parsed_nodename = VipnetParser::Nodename.new(file_content)
    records = parsed_nodename.records

    network = Network.find_or_create_by(network_vid: params[:network_vid])
    unless diff = Nodename.push(hash: records, belongs_to: network)
      Rails.logger.error("Unable to push hash")
      render plain: ERROR_RESPONSE and return
    end

    current_iplirconfs_snapshots = {}
    got_iplirconfs_snapshots = false
    diff.each do |changes|
      # parse changes
      # action = { "+" => :add, "-" => :remove, "~" => :change }[changes[0]]
      # target = {}
      # target[:vid], target[:field] = HashDiffSym.decode_property_path(changes[1])
      # if action == :change
      #   before = changes[2]
      #   after = changes[3]
      # end
      # if action == :add || action == :remove
      #   props = changes[2]
      # end
      action, target, props, before, after = Garland.decode_change(changes)
      curent_network_vid = VipnetParser::network(target[:vid])

      # skip ignored networks
      networks_to_ignore = Settings.networks_to_ignore.split(",")
      next if networks_to_ignore.include?(curent_network_vid)

      # skip extra nodes
      we_admin_this_network = !!Nodename.joins(:network).find_by("networks.network_vid": curent_network_vid)
      it_is_internetworking_node = network.network_vid != curent_network_vid
      next if we_admin_this_network && it_is_internetworking_node

      # skip groups
      if records[target[:vid]]
        next if records[target[:vid]][:category] == :group
      elsif props[:category]
        next if props[:category] == :group
      end

      if action == :add
        unless got_iplirconfs_snapshots
          Coordinator.all.each do |coord|
            current_iplirconfs_snapshots[coord.vid] = Iplirconf.snapshot(coord)
          end
          got_iplirconfs_snapshots = true
        end
        new_node = CurrentNode.new(vid: target[:vid], creation_date: DateTime.now, network_id: network.id)
        new_node.set_props_from_nodename(props)
        new_node.set_props_from_iplirconf(props: props, snapshots: current_iplirconfs_snapshots)
        new_node.save!
      end

      if action == :remove
        node_to_destroy = CurrentNode.find_by(vid: target[:vid])
        if node_to_destroy
          node_to_destroy.destroy
        else
          Rails.logger.error("CurrentNode with vid '#{target[:vid]}' doesn't exists, nothing to destroy")
        end
      end

      if action == :change
        changing_node = CurrentNode.find_by(vid: target[:vid])
        if changing_node
          changing_node[target[:field]] = after
          changing_node.save!
        else
          Rails.logger.error("CurrentNode with vid '#{target[:vid]}' doesn't exists, nothing to change")
        end
      end
    end

    render plain: OK_RESPONSE and return
  end
end

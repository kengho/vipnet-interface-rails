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
    nodename_is_not_first = Nodename.any?(network)
    unless diff = Nodename.push(hash: records, belongs_to: network)
      Rails.logger.error("Unable to push hash")
      render plain: ERROR_RESPONSE and return
    end

    iplirconfs_snapshots = {}
    got_iplirconfs_snapshots = false
    diff.each do |changes|
      action, target, props, before, after = Garland.decode_changes(changes)
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
            iplirconfs_snapshots[coord.vid] = (eval(Iplirconf.snapshot(coord).entity))
          end
          got_iplirconfs_snapshots = true
        end
        new_node = CurrentNode.new(vid: target[:vid], creation_date: DateTime.now, network_id: network.id)

        # iplirconfs_node_params if hash of all snapshots but with target[:vid] only
        iplirconfs_node_params = {}
        iplirconfs_snapshots.each do |k, snapshot|
          iplirconf_node_params = snapshot.clone
          iplirconf_node_params.reject! { |vid, _| vid != target[:vid] }
          iplirconfs_node_params[k] = iplirconf_node_params
        end

        new_node.set_props_from_nodename(props)
        new_node.set_props_from_iplirconf(iplirconfs_node_params)
        new_node.creation_date_accuracy = nodename_is_not_first

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

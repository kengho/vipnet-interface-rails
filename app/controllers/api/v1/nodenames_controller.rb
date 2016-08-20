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
      # parse diff
      action = { "+" => :add, "-" => :remove, "~" => :change }[changes[0]]
      target = {}
      tmp = changes[1].split(".")
      target[:vid] = tmp[0]
      if tmp[1]
        target[:field] = HashDiffSym.import_key(tmp[1])
      else
        target[:field] = nil
      end
      if action == :change
        before = changes[2]
        after = changes[3]
      end
      if action == :add || action == :remove
        props = changes[2]
      end
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
        node_to_destroy.destroy if node_to_destroy
      end

      if action == :change
        changing_node = CurrentNode.find_by(vid: target[:vid])
        changing_node[target[:field]] = after
        changing_node.save!
      end
    end
    
    render plain: OK_RESPONSE and return
  end
end

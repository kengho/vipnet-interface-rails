class Api::V1::NodenamesController < Api::V1::BaseController
  def create
    unless (params[:file] && params[:network_vid])
      Rails.logger.error("Incorrect params #{params}")
      render plain: ERROR_RESPONSE and return
    end

    nodename_file = File.read(params[:file].tempfile)
    nodename = VipnetParser::Nodename.new(nodename_file)
    nodename.parse({ normalize_names: true })

    network = Network.find_or_create_by(network_vid: params[:network_vid])
    nodename_is_not_first = Nodename.any?(network)
    diff = Nodename.push(
      hash: nodename.hash,
      belongs_to: network,
    )
    unless diff
      Rails.logger.error("Unable to push hash")
      render plain: ERROR_RESPONSE and return
    end
    nodename_created_at = diff.created_at
    records = nodename.hash[:id]

    ascendants_ids = []
    eval(diff.entity).each do |changes|
      changes_expanded = HashDiffSymUtils.expand_changes(changes)
      changes_expanded.each do |changes|
        action, target, props, before, after = HashDiffSymUtils.decode_changes(changes)
        curent_network_vid = VipnetParser.network(target[:vid])

        # skip ignored networks
        networks_to_ignore = Settings.networks_to_ignore.split(",")
        next if networks_to_ignore.include?(curent_network_vid)

        # skip extra nodes
        # "we admin network" means "we have Nodename for it"
        we_admin_this_network = !!Nodename.joins(:network)
          .find_by("networks.network_vid": curent_network_vid)
        it_is_internetworking_node = network.network_vid != curent_network_vid
        next if we_admin_this_network && it_is_internetworking_node

        # skip groups
        if records[target[:vid]]
          next if records[target[:vid]][:category] == :group
        elsif props[:category]
          next if props[:category] == :group
        end

        if action == :add
          deleted_ncc_node = DeletedNccNode.find_by(vid: target[:vid])

          # may occur only when old ncc db restores, no need for saving history
          if deleted_ncc_node
            deleted_ncc_node.update_attributes({
              type: "CurrentNccNode",
              deletion_date: nil,
            })
          else
            props.reject! { |p| !NccNode.props_from_nodename.include?(p) }
            CurrentNccNode.create!({
              vid: target[:vid],
              creation_date: nodename_created_at,
              network: network,
              creation_date_accuracy: nodename_is_not_first,
            }.merge(props))
          end
        end

        if action == :remove
          ncc_node_to_delete = CurrentNccNode.find_by(vid: target[:vid])
          if ncc_node_to_delete
            ncc_node_to_delete.update_attributes({
              type: "DeletedNccNode",
              deletion_date: nodename_created_at,
            })
          else
            Rails.logger.info(
              "CurrentNccNode with vid '#{target[:vid]}'
              doesn't exists, nothing to delete"
            .squish)
          end
        end

        if action == :change
          # [["~", "0x1a0e000c.:name", "client1", "client1-renamed1"]]
          if NccNode.props_from_nodename.include?(target[:field])
            changing_ncc_node = CurrentNccNode.find_by(vid: target[:vid])
            if changing_ncc_node
              ascendant = NccNode
                .where(id: ascendants_ids)
                .find_by(descendant: changing_ncc_node)
              if ascendant
                ascendant.update_attribute(target[:field], before)
              else
                new_ascendant = NccNode.new(
                  :descendant => changing_ncc_node,
                  :creation_date => nodename_created_at,
                  target[:field] => before,
                )
                if new_ascendant.save!
                  ascendants_ids.push(new_ascendant.id)
                else
                  Rails.logger.info("Unable to save new_ascendant: #{new_ascendant.inspect}")
                end
              end
              changing_ncc_node.update_attribute(target[:field], after)
            else
              Rails.logger.info(
                "CurrentNccNode with vid '#{target[:vid]}'
                doesn't exists, nothing to change"
              .squish)
            end
          else
            Rails.logger.info(
              "Trying to change wrong field '#{target[:field]}'
              in CurrentNccNode via nodename API"
            .squish)
          end
        end
      end
    end

    if minutes_after_latest_update("ncc_nodes") < 5
      UpdateChannel.push(update: true)
    end
    render plain: OK_RESPONSE and return
  end
end

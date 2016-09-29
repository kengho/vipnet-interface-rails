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

    ascendants_ids = []
    diff.each do |changes|
      action, target, props, before, after = Garland.decode_changes(changes)
      curent_network_vid = VipnetParser::network(target[:vid])

      # skip ignored networks
      networks_to_ignore = Settings.networks_to_ignore.split(",")
      next if networks_to_ignore.include?(curent_network_vid)

      # skip extra nodes
      # "we admin network" means "we have Nodename for it"
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
        props.reject! { |p| !NccNode.props_from_nodename.include?(p) }
        CurrentNccNode.create!({
          vid: target[:vid],
          creation_date: DateTime.now,
          network: network,
          creation_date_accuracy: nodename_is_not_first,
        }.merge(props))
      end

      if action == :remove
        ncc_node_to_delete = CurrentNccNode.find_by(vid: target[:vid])
        if ncc_node_to_delete
          ncc_node_to_delete.update_attribute(:type, "DeletedNccNode")
        else
          Rails.logger.info("CurrentNccNode with vid '#{target[:vid]}' doesn't exists, nothing to delete")
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
            Rails.logger.info("CurrentNccNode with vid '#{target[:vid]}' doesn't exists, nothing to change")
          end
        else
          Rails.logger.info("Trying to change wrong field '#{target[:field]}' in CurrentNccNode via nodename API")
        end
      end
    end
    render plain: OK_RESPONSE and return
  end
end

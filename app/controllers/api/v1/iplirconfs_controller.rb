class Api::V1::IplirconfsController < Api::V1::BaseController
  def create
    unless (params[:file] && params[:coord_vid])
      Rails.logger.error("Incorrect params #{params}")
      render plain: ERROR_RESPONSE and return
    end

    iplirconf_file = File.read(params[:file].tempfile)
    iplirconf = VipnetParser::Iplirconf.new(iplirconf_file)
    iplirconf.parse()

    coord_vid = params[:coord_vid]
    network = Network.find_or_create_by(network_vid: VipnetParser::network(coord_vid))
    coordinator = Coordinator.find_or_create_by(vid: coord_vid, network: network)
    diff, iplirconf_created_at = Iplirconf.push(hash: iplirconf.hash, belongs_to: coordinator, partial: :id)
    unless diff
      Rails.logger.error("Unable to push hash")
      render plain: ERROR_RESPONSE and return
    end

    ascendants_ids = []
    diff.each do |changes|
      action, target, props, before, after = Garland.decode_changes(changes)
      ncc_node = CurrentNccNode.find_by(vid: target[:vid])
      if ncc_node
        if action == :add
          if target[:field] && target[:index]
            # ["+", "0x1a0e000b.:ip[0]", "192.0.2.55"]
            if target[:field] == :ip && IPv4::ip?(props)
              hw_node = CurrentHwNode.find_by({
                ncc_node: ncc_node,
                coordinator: coordinator,
              })
              NodeIp.create!(hw_node: hw_node, u32: IPv4::u32(props))
            end
          else
            # ["+", "0x1a0e000a", {:id=>"0x1a0e000a", :name=>"coordinator1", ... }]
            # (entire section is added)
            # at first, we are trying to figure out, was there such section in past or not?
            # maybe link between node and coordinator was deleted and added again
            # if so, HwNode should go from "DeletedHwNode" to "CurrentHwNode" and it's attributes should be upgraded
            # also, old attributes of deleted_hw_node should be saved in ascendant
            # (at this point we don't save HwNode's status ("Deleted" or "Current") in ascendant)
            deleted_hw_node = DeletedHwNode.find_by(
              ncc_node: ncc_node,
              coordinator: coordinator,
            )
            if deleted_hw_node
              new_section_props = props.reject do |attribute, _|
                !(HwNode.props_from_iplirconf).include?(attribute)
              end
              accendant_props = deleted_hw_node.attributes.reject do |attribute, _|
                !(HwNode.props_from_iplirconf).include?(attribute.to_sym)
              end
              new_accendant = HwNode.new(
                {
                  descendant: deleted_hw_node,
                  creation_date: iplirconf_created_at,
                }.merge(accendant_props)
              )
              if new_accendant.save
                deleted_hw_node.node_ips.each do |node_ip|
                  node_ip.update_attribute(:hw_node_id, new_accendant.id)
                end
              else
                Rails.logger.info("Unable to save new_accendant: #{new_accendant.inspect}")
              end
              # if some prop was deleted, new_section_props will lack of it,
              # thus update_attributes will leave this prop as it was before,
              # but we want it to become nil
              # http://stackoverflow.com/a/11772866/6376451
              nil_props = Hash[*HwNode.props_from_iplirconf.map { |x| [x, nil] }.flatten]
              new_section_props = nil_props.merge(new_section_props)
              deleted_hw_node.update_attributes({ type: "CurrentHwNode" }.merge(new_section_props))
              if props[:ip]
                props[:ip].each do |ip|
                  NodeIp.create!(hw_node: deleted_hw_node, u32: IPv4::u32(ip)) if IPv4::ip?(ip)
                end
              end
            else
              hw_node = CurrentHwNode.new({
                ncc_node: ncc_node,
                coordinator: coordinator,
                creation_date: iplirconf_created_at,
              }.merge(props.reject { |p| !HwNode.props_from_iplirconf.include?(p) }))
              hw_node.save!
              if props[:ip]
                props[:ip].each do |ip|
                  NodeIp.create!(hw_node: hw_node, u32: IPv4::u32(ip)) if IPv4::ip?(ip)
                end
              end
            end
          end
        end

        if action == :remove
          if target[:field] && target[:index]
            # ["-", "0x1a0e000a.:ip[0]", "192.0.2.51"]
            if target[:field] == :ip && IPv4::ip?(props)
              changing_hw_node = CurrentHwNode.find_by({
                ncc_node: ncc_node,
                coordinator: coordinator,
              })
              node_ip = NodeIp.find_by(hw_node: changing_hw_node, u32: IPv4::u32(props))
              if changing_hw_node && node_ip
                accendant = HwNode
                  .where(id: ascendants_ids)
                  .find_by(descendant: changing_hw_node)
                if accendant
                  node_ip.update_attribute(:hw_node_id, accendant.id)
                else
                  new_accendant = HwNode.new(
                    descendant: changing_hw_node,
                    creation_date: iplirconf_created_at,
                  )
                  if new_accendant.save!
                    ascendants_ids.push(new_accendant.id)
                    node_ip.update_attribute(:hw_node_id, new_accendant.id)
                  else
                    Rails.logger.info("Unable to save new_accendant: #{new_accendant.inspect}")
                  end
                end
              else
                Rails.logger.info("CurrentHwNode with ncc_node: #{ncc_node.inspect}, "\
                "coordinator: #{coordinator.inspect} doesn't exist or has no node_ip '#{props}'")
              end
            end
          else
            # ["-", "0x1a0e000c", {:id=>"0x1a0e000c", ...]
            # (entire section is deleted)
            hw_node_to_delete = CurrentHwNode.find_by({
              ncc_node: ncc_node,
              coordinator: coordinator,
            })
            if hw_node_to_delete
              hw_node_to_delete.update_attribute(:type, "DeletedHwNode")
            else
              Rails.logger.info("CurrentHwNode with ncc_node: #{ncc_node.inspect}, "\
              "coordinator: #{coordinator.inspect} doesn't exists, nothing to delete")
            end
          end
        end

        if action == :change
          # ["~", "0x1a0e000b.:version", "3.2-673", "3.2-672"]
          if HwNode.props_from_iplirconf.include?(target[:field])
            changing_hw_node = CurrentHwNode.find_by(ncc_node: ncc_node, coordinator: coordinator)
            if changing_hw_node
              accendant = HwNode
                .where(id: ascendants_ids)
                .find_by(descendant: changing_hw_node)
              if accendant
                accendant.update_attribute(target[:field], before)
              else
                new_accendant = HwNode.new(
                  :descendant => changing_hw_node,
                  :creation_date => iplirconf_created_at,
                  target[:field] => before,
                )
                if new_accendant.save!
                  ascendants_ids.push(new_accendant.id)
                else
                  Rails.logger.info("Unable to save new_accendant: #{new_accendant.inspect}")
                end
              end
              changing_hw_node.update_attribute(target[:field], after)
            else
              Rails.logger.info("CurrentHwNode with ncc_node: #{ncc_node.inspect}, "\
              "coordinator: #{coordinator.inspect} doesn't exists, nothing to change")
            end
          end
        end
      end
    end
    render plain: OK_RESPONSE and return
  end
end

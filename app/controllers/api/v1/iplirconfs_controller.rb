class Api::V1::IplirconfsController < Api::V1::BaseController
  def create
    unless params[:file] && params[:coord_vid]
      Rails.logger.error("Incorrect params #{params}")
      render plain: ERROR_RESPONSE and return
    end

    iplirconf_file = File.read(params[:file].tempfile)
    iplirconf = VipnetParser::Iplirconf.new(iplirconf_file)
    iplirconf.parse

    coord_vid = params[:coord_vid]
    network = Network
                .find_or_create_by(network_vid: VipnetParser.network(coord_vid))
    coordinator = Coordinator
                    .find_or_create_by(vid: coord_vid, network: network)
    diff = Iplirconf.push(
      hash: iplirconf.hash,
      belongs_to: coordinator,
    )
    unless diff
      Rails.logger.error("Unable to push hash")
      render plain: ERROR_RESPONSE and return
    end
    iplirconf_created_at = diff.created_at

    ascendants_ids = []
    diff.safe_eval_entity.each do |changes|
      changes_expanded = HashDiffSymUtils.expand_changes(changes)
      changes_expanded.each do |change|
        action, target, props, before, after = HashDiffSymUtils
                                                 .decode_changes(change)
        ncc_node = CurrentNccNode.find_by(vid: target[:vid])
        next unless ncc_node

        # FIXME
        # rubocop:disable Metrics/BlockNesting
        if action == :add
          if target[:field] && target[:index]
            # ["+", "0x1a0e000b.:ip[0]", "192.0.2.55"]
            if target[:field] == :ip && IPv4.ip?(props)
              hw_node = CurrentHwNode.find_by(
                ncc_node: ncc_node,
                coordinator: coordinator,
              )
              NodeIp.create!(hw_node: hw_node, u32: IPv4.u32(props))
            end
          else
            # ["+", "0x1a0e000a", {:id=>"0x1a0e000a", :name=>"coordinator1", ... }]
            # Entire section is added.
            # At first, we are trying to figure out, was there such section in past or not?
            # Maybe connection between node and coordinator was deleted and added again?
            # If so, HwNode should go from "DeletedHwNode" to "CurrentHwNode" and it's attributes should be upgraded.
            # Also, old attributes of "deleted_hw_node" should be saved in ascendant.
            # (At this point we don't save HwNode's status ("Deleted" or "Current") in ascendant.)
            deleted_hw_node = DeletedHwNode.find_by(
              ncc_node: ncc_node,
              coordinator: coordinator,
            )
            if deleted_hw_node
              new_section_props = props.reject do |attribute, _|
                !HwNode.props_from_iplirconf.include?(attribute)
              end
              accendant_props = deleted_hw_node
                                  .attributes
                                  .reject do |attribute, _|
                                    !HwNode.props_from_iplirconf
                                       .include?(attribute.to_sym)
                                  end
              accendant_props = {
                descendant: deleted_hw_node,
                creation_date: iplirconf_created_at,
              }.merge(accendant_props)
              new_accendant = HwNode.new(accendant_props)
              if new_accendant.save
                deleted_hw_node.node_ips.each do |node_ip|
                  node_ip.update_attributes(hw_node_id: new_accendant.id)
                end
              else
                Rails.logger.info(
                  "Unable to save new_accendant:
                  #{new_accendant.inspect}".squish,
                )
              end

              # If some prop was deleted, "new_section_props" will lack of it,
              # thus "update_attributes" will leave this prop as it was before,
              # but we want it to become "nil".
              # http://stackoverflow.com/a/11772866/6376451
              # ["prop1", "prop2", "prop3"] =>  { "prop1"=>nil, "prop2"=>nil, "prop3"=>nil }
              nil_props = Hash[*HwNode
                            .props_from_iplirconf
                            .flat_map { |x| [x, nil] }
              ]
              new_section_props = nil_props.merge(new_section_props)
              deleted_hw_node_props = {
                type: "CurrentHwNode",
              }.merge(new_section_props)
              deleted_hw_node.update_attributes(deleted_hw_node_props)
              if props[:ip]
                props[:ip].each do |ip|
                  if IPv4.ip?(ip)
                    NodeIp.create!(hw_node: deleted_hw_node, u32: IPv4.u32(ip))
                  end
                end
              end
            else
              included_props = props.reject do |p|
                !HwNode.props_from_iplirconf.include?(p)
              end
              hw_node_props = {
                ncc_node: ncc_node,
                coordinator: coordinator,
                creation_date: iplirconf_created_at,
              }.merge(included_props)
              hw_node = CurrentHwNode.new(hw_node_props)
              hw_node.save!
              if props[:ip]
                props[:ip].each do |ip|
                  if IPv4.ip?(ip)
                    NodeIp.create!(hw_node: hw_node, u32: IPv4.u32(ip))
                  end
                end
              end
            end
          end
        elsif action == :remove
          if target[:field] && target[:index]
            # ["-", "0x1a0e000a.:ip[0]", "192.0.2.51"]
            if target[:field] == :ip && IPv4.ip?(props)
              changing_hw_node = CurrentHwNode.find_by(
                ncc_node: ncc_node,
                coordinator: coordinator,
              )
              node_ip = NodeIp.find_by(
                hw_node: changing_hw_node,
                u32: IPv4.u32(props),
              )
              if changing_hw_node && node_ip
                accendant = HwNode
                              .where(id: ascendants_ids)
                              .find_by(descendant: changing_hw_node)
                if accendant
                  node_ip.update_attributes(hw_node_id: accendant.id)
                else
                  new_accendant = HwNode.new(
                    descendant: changing_hw_node,
                    creation_date: iplirconf_created_at,
                  )
                  if new_accendant.save!
                    ascendants_ids.push(new_accendant.id)
                    node_ip.update_attributes(hw_node_id: new_accendant.id)
                  else
                    Rails.logger.info(
                      "Unable to save new_accendant:
                      #{new_accendant.inspect}".squish,
                    )
                  end
                end
              else
                Rails.logger.info(
                  "CurrentHwNode with ncc_node: #{ncc_node.inspect},
                  coordinator: #{coordinator.inspect}
                  doesn't exist or has no node_ip '#{props}'".squish,
                )
              end
            end
          else
            # ["-", "0x1a0e000c", {:id=>"0x1a0e000c", ...]
            # (Entire section is deleted.)
            hw_node_to_delete = CurrentHwNode.find_by(
              ncc_node: ncc_node,
              coordinator: coordinator,
            )
            if hw_node_to_delete
              hw_node_to_delete.update_attributes(type: "DeletedHwNode")
            else
              Rails.logger.info(
                "CurrentHwNode with ncc_node: #{ncc_node.inspect},
                coordinator: #{coordinator.inspect} doesn't exists,
                nothing to delete".squish,
              )
            end
          end
        elsif action == :change
          # ["~", "0x1a0e000b.:version", "3.2-673", "3.2-672"]
          if HwNode.props_from_iplirconf.include?(target[:field])
            changing_hw_node = CurrentHwNode.find_by(
              ncc_node: ncc_node,
              coordinator: coordinator,
            )
            if changing_hw_node
              accendant = HwNode
                            .where(id: ascendants_ids)
                            .find_by(descendant: changing_hw_node)
              if accendant
                accendant.update_attributes(target[:field] => before)
              else
                new_accendant = HwNode.new(
                  :descendant => changing_hw_node,
                  :creation_date => iplirconf_created_at,
                  target[:field] => before,
                )
                if new_accendant.save!
                  ascendants_ids.push(new_accendant.id)
                else
                  Rails.logger.info(
                    "Unable to save new_accendant:
                    #{new_accendant.inspect}".squish,
                  )
                end
              end
              changing_hw_node.update_attributes(target[:field] => after)
            else
              Rails.logger.info(
                "CurrentHwNode with ncc_node: #{ncc_node.inspect},
                coordinator: #{coordinator.inspect} doesn't exists,
                nothing to change".squish,
              )
            end
          end
        end
        # rubocop:enable Metrics/BlockNesting
      end
    end

    if minutes_after_latest_update("hw_nodes", "node_ips") < 5
      UpdateChannel.push(update: true)
    end

    render plain: OK_RESPONSE
  end
end

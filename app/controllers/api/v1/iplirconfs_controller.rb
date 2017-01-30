class Api::V1::IplirconfsController < Api::V1::BaseController
  def create
    coordinator, creation_date, diff = Utils.prepare(params)

    # Storage for ids of accendants created within one create() run.
    # Uses to group changes that happened at once in one accendant.
    ascendants_ids = []
    diff.each do |changes|
      changes_expanded = HashDiffSymUtils.expand_changes(changes)
      changes_expanded.each do |change|
        action, target, props, before, after = HashDiffSymUtils
                                                 .decode_changes(change)

        # Drop useless changes like
        # ["+", "0x1a0e000b.:accessiplist[0]", "192.0.2.7, auto, 0.0.0.0, 0, auto"],
        # but keep changes without field (for entire sections) like
        # ["+", "0x1a0e000a", {:id=>"0x1a0e000a", :name=>"coordinator1", ... }]
        change_is_useful = HwNode.props_from_iplirconf
                             .include?(target[:field]) ||
                           !target[:field]
        next unless change_is_useful

        # Clear hash props from useless attributes.
        if props.class == Hash
          props.reject! do |prop, _|
            !HwNode.props_from_iplirconf.include?(prop)
          end
        end

        ncc_node = CurrentNccNode.find_by(vid: target[:vid])
        next unless ncc_node

        if action == :add
          if target[:field] == :ip && target[:index]
            # TODO: add "IPv4.ip?(ip)" check to VipnetParser.
            hw_node = CurrentHwNode.find_by(
              ncc_node: ncc_node,
              coordinator: coordinator,
            )
            next unless hw_node

            NodeIp.create!(hw_node: hw_node, u32: IPv4.u32(props))

            next
          end

          # ["+", "0x1a0e000a", {:id=>"0x1a0e000a", :name=>"coordinator1", ... }]
          # Entire section is added.
          deleted_hw_node = DeletedHwNode.find_by(
            ncc_node: ncc_node,
            coordinator: coordinator,
          )
          if deleted_hw_node
            deleted_hw_node.undelete(props, creation_date)
          else
            hw_node_props = props.merge(
              ncc_node: ncc_node,
              coordinator: coordinator,
              creation_date: creation_date,
            )
            CurrentHwNode.create_with_ips(hw_node_props)
          end
        elsif action == :remove
          if target[:field] == :ip && target[:index]
            # IP deleted.
            # ["-", "0x1a0e000a.:ip[0]", "192.0.2.51"]
            changing_hw_node = CurrentHwNode.find_by(
              ncc_node: ncc_node,
              coordinator: coordinator,
            )
            next unless changing_hw_node

            accendant = changing_hw_node.find_or_create_accendant(
              ascendants_ids,
              creation_date,
            )
            changing_hw_node.delete_ip(props, accendant)

            next
          end

          # Entire section is deleted.
          # ["-", "0x1a0e000c", {:id=>"0x1a0e000c", ...]
          hw_node_to_delete = CurrentHwNode.find_by(
            ncc_node: ncc_node,
            coordinator: coordinator,
          )
          next unless hw_node_to_delete

          hw_node_to_delete.update_attributes(type: "DeletedHwNode")
        elsif action == :change
          # ["~", "0x1a0e000b.:version", "3.2-673", "3.2-672"]
          # (IP cannot change, it only adds or deletes.)
          changing_hw_node = CurrentHwNode.find_by(
            ncc_node: ncc_node,
            coordinator: coordinator,
          )
          next unless changing_hw_node

          accendant = changing_hw_node.find_or_create_accendant(
            ascendants_ids,
            creation_date,
          )
          accendant.update_attributes(target[:field] => before)
          changing_hw_node.update_attributes(target[:field] => after)
        end
      end
    end

    # TODO: move to after_something.
    if minutes_after_latest_update("hw_nodes", "node_ips") < 5
      UpdateChannel.push(update: true)
    end

    render plain: OK_RESPONSE
  end
end

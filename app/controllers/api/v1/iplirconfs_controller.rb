class Api::V1::IplirconfsController < Api::V1::BaseController
  def create
    unless (params[:file] && params[:coord_vid])
      Rails.logger.error("Incorrect params #{params}")
      render plain: ERROR_RESPONSE and return
    end

    file_content = File.read(params[:file].tempfile)
    parsed_iplirconf = VipnetParser::Iplirconf.new(file_content)
    sections = parsed_iplirconf.sections

    coord_vid = params[:coord_vid]
    network = Network.find_or_create_by(network_vid: VipnetParser::network(coord_vid))
    coordinator = Coordinator.find_or_create_by(vid: coord_vid, network: network)
    unless diff = Iplirconf.push(hash: sections, belongs_to: coordinator)
      Rails.logger.error("Unable to push hash")
      render plain: ERROR_RESPONSE and return
    end
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
            hw_node = CurrentHwNode.new({
              ncc_node: ncc_node,
              coordinator: coordinator,
            }.merge(props.reject { |p| !HwNode.props_from_iplirconf.include?(p) }))
            hw_node.save!
            if props[:ip]
              props[:ip].each do |ip|
                NodeIp.create!(hw_node: hw_node, u32: IPv4::u32(ip)) if IPv4::ip?(ip)
              end
            end
          end
        end

        if action == :remove
          if target[:field] && target[:index]
            # ["-", "0x1a0e000a.:ip[0]", "192.0.2.51"]
            if target[:field] == :ip && IPv4::ip?(props)
              hw_node = CurrentHwNode.find_by({
                ncc_node: ncc_node,
                coordinator: coordinator,
              })
              node_ip = NodeIp.find_by(hw_node: hw_node, u32: IPv4::u32(props))
              node_ip.destroy! if node_ip
            end
          else
            # ["-", "0x1a0e000c", {:id=>"0x1a0e000c", ...]
            # (entire section is deleted)
            hw_node = CurrentHwNode.find_by({
              ncc_node: ncc_node,
              coordinator: coordinator,
            })
            hw_node.destroy! if hw_node
          end
        end

        if action == :change
          # ["~", "0x1a0e000b.:version", "3.2-673", "3.2-672"]
          hw_node = CurrentHwNode.find_by(ncc_node: ncc_node, coordinator: coordinator)
          if hw_node && HwNode.props_from_iplirconf.include?(target[:field])
            hw_node.update_attribute(target[:field], after)
          end
        end
      end
    end
    render plain: OK_RESPONSE and return
  end
end

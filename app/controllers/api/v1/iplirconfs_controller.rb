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
      node = CurrentNode.find_by(vid: target[:vid])
      if node
        if action == :add
          if target[:field] && target[:index]
            # ["+", "0x1a0e000b.:ip[0]", "192.0.2.55"]
            arr = eval(node[target[:field]][coord_vid])
            arr.insert(target[:index], props)
            node[target[:field]][coord_vid] = arr
            NodeIp.add_ip(coordinator, node, target[:field], props)
          else
            # ["+", "0x1a0e000a", {:id=>"0x1a0e000a", :name=>"coordinator1", ... }]
            node.set_props_from_iplirconf(coord_vid => { target[:vid] => props })
            NodeIp.create_ips(coordinator, node, props)
          end
        end

        if action == :remove
          if target[:field] && target[:index]
            # ["-", "0x1a0e000a.:ip[0]", "192.0.2.51"]
            arr = eval(node[target[:field]][coord_vid])
            arr.delete_at(target[:index])
            node[target[:field]][coord_vid] = arr
            NodeIp.remove_ip(coordinator, node, target[:field], props)
          end
        end

        if action == :change
          # ["~", "0x1a0e000b.:version", "3.2-673", "3.2-672"]
          node[target[:field]][coord_vid] = after if Iplirconf.props_from_api.include?(target[:field])
          NodeIp.change_ip(coordinator, node, target[:field], before, after)
        end

        node.save!
      end
    end
    render plain: OK_RESPONSE and return
  end
end

class Api::V1::AccessipsController < Api::V1::BaseController

  def index
    @response = Hash.new
    if params[:accessip]
      nodes = Node.none
      vipnet_ids = Array.new
      only = params[:only] || ["vipnet_id", "enabled"]
      iplirconfs = Iplirconf.all
    else
      @response[:errors] = [{
        title: "external",
        detail: "Expected accessip as param",
        links: {
          related: {
            href: "/api/v1/doc"
          }
        }
      }]
      render json: @response and return
    end

    iplirconfs.each do |iplirconf|
      iplirconf.sections.each do |_, section|
        vipnet_ids.push(eval(section)["vipnet_id"]) if eval(section)["accessip"] == params[:accessip]
        if eval(section)["accessip"] == params[:accessip]
          new_nodes = Node.where("vipnet_id = ? AND history = 'false' AND deleted_at is null", eval(section)["vipnet_id"])
          nodes = nodes | new_nodes
        end
      end
    end
    if nodes.size == 0
      @response[:errors] = [{title: "external", detail: "Node not found"}]
      render json: @response and return
    elsif nodes.size == 1
      node = nodes.first
      @response[:data] = @response.merge(node.attributes.slice(*only))
      render json: @response and return
    elsif nodes.size > 1
      @response[:errors] = [{
        title: "internal",
        detail: "Please report to developer. "\
                "Multiple nodes found. "\
                "Params: #{params.except(:token)}"
      }]
      render json: @response and return
    end
  end

end

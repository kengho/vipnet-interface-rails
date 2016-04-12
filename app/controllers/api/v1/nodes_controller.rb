class Api::V1::NodesController < Api::V1::BaseController

  def index
    @response = Hash.new
    if params[:vipnet_id]
      only = params[:only] || ["name", "enabled"]
      nodes = Node.where("vipnet_id = ? AND history = 'false' AND deleted_at is null", params[:vipnet_id])
    else
      @response[:errors] = [{
        title: "external",
        detail: "Expected vipnet_id as param",
        links: {
          related: {
            href: "/api/v1/doc"
          }
        }
      }]
      render json: @response and return
    end

    if nodes.size == 0
      @response[:errors] = [{title: "external", detail: "Node not found"}]
      render json: @response and return
    elsif nodes.size == 1
      node = nodes.first
      @response[:data] = @response.merge(node.attributes.slice(*only))
      if params[:availability] == "true"
        availability = node.availability
        if availability["status"] == "success"
          @response[:data][:available] = availability["availability"]
        else
          @response[:data][:available] = false
        end
      end
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

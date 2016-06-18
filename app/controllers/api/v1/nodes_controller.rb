class Api::V1::NodesController < Api::V1::BaseController
  def index
    @response = Hash.new
    if params[:vipnet_id]
      only = params[:only] || ["name", "enabled"]
      node = Node.find_by(vipnet_id: params[:vipnet_id], history: false, deleted_at: nil)
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

    if node
      @response[:data] = @response.merge(node.attributes.slice(*only))
      if params[:availability] == "true"
        availability = node.availability
        if availability[:data]
          @response[:data]["available"] = availability[:data][:availability]
        else
          @response[:data]["available"] = false
        end
      end
    else
      @response[:errors] = [{ title: "external", detail: "Node not found" }]
    end
    render json: @response and return
  end
end

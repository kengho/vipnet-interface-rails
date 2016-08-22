class Api::V1::NodesController < Api::V1::BaseController
  def index
    @response = Hash.new
    if params[:vid]
      only = params[:only] || ["name"]
      node = CurrentNode.find_by(vid: params[:vid])
    else
      @response[:errors] = [{
        title: "external",
        detail: "Expected vid as param",
        links: {
          related: {
            href: "/api/v1/doc"
          }
        }
      }]
      render json: @response and return
    end

    if node
      @response[:data] = node.attributes.slice(*only).symbolize_keys
    else
      @response[:errors] = [{ title: "external", detail: "Node not found" }]
    end
    render json: @response and return
  end
end

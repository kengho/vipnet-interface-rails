class Api::V1::AccessipsController < Api::V1::BaseController
  def index
    @response = {}
    unless params[:accessip]
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
    unless IPv4::ip?(params[:accessip])
      @response[:errors] = [{ title: "external", detail: "Expected valid IPv4 as 'accessip' param" }]
      render json: @response and return
    end

    ncc_node = CurrentNccNode.joins(:hw_nodes).find_by("hw_nodes.accessip": params[:accessip])
    if ncc_node
      @response[:data] = { "vid" => ncc_node.vid }
      render json: @response and return
    else
      @response[:errors] = [{ title: "external", detail: "Node not found" }]
      render json: @response and return
    end
  end
end

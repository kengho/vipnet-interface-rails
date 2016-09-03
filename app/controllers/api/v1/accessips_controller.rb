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

    node = CurrentNode.joins(:access_ips).find_by("node_ips.u32": IPv4::u32(params[:accessip]))
    if node
      @response[:data] = { "vid" => node.vid }
      render json: @response and return
    else
      @response[:errors] = [{ title: "external", detail: "Node not found" }]
      render json: @response and return
    end
  end
end

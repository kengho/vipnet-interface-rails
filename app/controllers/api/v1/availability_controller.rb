class Api::V1::AvailabilityController < Api::V1::BaseController
  def index
    @response = {}
    unless params[:vid]
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

    ncc_node = NccNode.find_by(vid: params[:vid])
    if ncc_node
      @response = ncc_node.availability
    else
      @response[:errors] = [{ title: "external", detail: "Node not found" }]
    end
    render json: @response and return
  end
end

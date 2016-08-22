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

    if only.class != Array
      @response[:errors] = [{
        title: "external",
        detail: "Only should be an array",
        links: {
          related: {
            href: "/api/v1/doc"
          }
        }
      }]
      render json: @response and return
    end

    if node
      avaliable_fileds = [
        "vid", "name", "ip", "accessip", "version", "version_decoded",
        "enabled", "category", "creation_date", "creation_date_accuracy",
      ]
      @response[:data] = node.attributes.slice(*only & avaliable_fileds)
    else
      @response[:errors] = [{ title: "external", detail: "Node not found" }]
    end
    render json: @response and return
  end
end

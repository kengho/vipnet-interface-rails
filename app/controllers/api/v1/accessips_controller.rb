class Api::V1::AccessipsController < Api::V1::BaseController
  def index
    @response = Hash.new
    if params[:accessip]
      nodes = CurrentNode.none
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

    Coordinator.all.each do |coord|
      new_nodes = CurrentNode.where("accessip -> '#{coord.vid}' = ?", params[:accessip])
      nodes = nodes | new_nodes
    end

    if nodes.size == 0
      @response[:errors] = [{ title: "external", detail: "Node not found" }]
      render json: @response and return
    elsif nodes.size == 1
      @response[:data] = @response.merge({ vid: nodes.first.vid })
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

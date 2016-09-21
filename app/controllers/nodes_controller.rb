class NodesController < ApplicationController
  skip_before_action :check_administrator_role
  before_action :check_if_node_exist, only: [:info, :availability]

  def index
    @search = false
    if params["search"]
      @search = true
      search_resuls = CurrentNccNode.none
      param = params["search"].strip
      NccNode.view_order.each do |order|
        prop, _, _ = order
        search_method = "where_#{prop}_like".to_sym
        if NccNode.methods.include?(search_method)
          search_resuls = search_resuls | CurrentNccNode.public_send(search_method, param)
        end
      end
    else
      search_resuls = CurrentNccNode.all
      params_expanded = params.each { |_, value| value.strip! }
      params_expanded.reject! { |_, value| value.empty? }
      params_expanded.each do |key, param|
        search_method = "where_#{key}_like".to_sym
        if NccNode.methods.include?(search_method)
          @search = true
          search_resuls = search_resuls & CurrentNccNode.public_send(search_method, param)
        end
      end
    end
    if @search
      # http://stackoverflow.com/a/24448317/6376451
      @ncc_nodes = CurrentNccNode.where(id: search_resuls.map(&:id)).order(vid: :asc)
      @size = @ncc_nodes.size
    else
      @ncc_nodes = CurrentNccNode.order(creation_date: :desc)
    end
    CurrentNccNode.per_page = current_user.settings["nodes_per_page"] || Settings.nodes_per_page
    @ncc_nodes = @ncc_nodes.paginate(page: params[:page]).includes(:hw_nodes, hw_nodes: [:node_ips])
    @js = "vipnetInterface.nodesData = {};"
  end

  respond_to :js

  def info
    @response = {
      parent_id: "#node-#{@ncc_node.id}__info",
      row_id: "#node-#{@ncc_node.id}__row",
      tooltip_text: t("nodes.row.info.loaded"),
      ncc_node: @ncc_node,
    }
    respond_with(@response, template: "nodes/row/info") and return
  end

  def availability
    @response = {
      parent_id: "#node-#{@ncc_node.id}__check-availability"
    }
    availability = @ncc_node.availability
    if availability[:errors]
      @response[:status] = false
      @response[:tooltip_text] = t("nodes.fullscreen_tooltip.#{availability[:errors][0][:detail]}.short")
      @response[:fullscreen_tooltip_key] = availability[:errors][0][:detail]
    else
      @response[:status] = availability[:data][:availability]
      @response[:tooltip_text] = t("nodes.row.availability.status_#{@response[:status]}")
      @response[:fullscreen_tooltip_key] = "node-unavailable" if @response[:status] == false
    end
    respond_with(@response, template: "nodes/row/remote_status_button") and return
  end

  private
    def check_if_node_exist
      @ncc_node = NccNode.find_by_id(params[:node_id])
      render nothing: true, status: :bad_request, content_type: "text/html" and return unless @ncc_node
    end
end

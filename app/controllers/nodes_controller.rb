class NodesController < ApplicationController
  skip_before_action :check_administrator_role
  before_action :check_if_ncc_node_exist, only: [:info, :history, :availability]

  def index
    @params = params.reject { |k, _| ["controller", "action"].include?(k) }
  end

  respond_to :js

  def load
    @search = false
    params_expanded = params.each { |_, value| value.strip! }
    params_expanded.reject! do |key, value|
      value.empty? ||
      ["controller", "action", "_"].include?(key) ||
      false
    end

    if params_expanded["search"]
      @search = true
      search_resuls = NccNode.none
      param = params_expanded["search"]
      NccNode.quick_searchable.each do |prop|
        search_method = "where_#{prop}_like".to_sym
        if NccNode.methods.include?(search_method)
          search_resuls = search_resuls | NccNode.public_send(search_method, param)
        end
      end
    else
      search_resuls = NccNode.all
      params_expanded.each do |key, param|
        search_method = "where_#{key}_like".to_sym
        if NccNode.methods.include?(search_method)
          @search = true
          search_resuls = search_resuls & NccNode.public_send(search_method, param)
        end
      end
    end

    if @search
      # http://stackoverflow.com/a/24448317/6376451
      all_ncc_nodes = NccNode
        .where(id: search_resuls.map(&:id))
        .order(vid: :asc)
      current_ncc_nodes = all_ncc_nodes.where(type: "CurrentNccNode")
      if current_ncc_nodes.size > 0
        @ncc_nodes = current_ncc_nodes
      else
        @ncc_nodes = all_ncc_nodes
      end
      # calculating size here because of paginate() later
      @size = @ncc_nodes.size
    else
      # there are mess in pagination if creation_date is the same
      # and there are only one ordering prop
      @ncc_nodes = CurrentNccNode.order(creation_date: :desc, vid: :desc)
    end

    CurrentNccNode.per_page = current_user.settings["nodes_per_page"] || Settings.nodes_per_page
    @ncc_nodes = @ncc_nodes
      .paginate(page: params[:page])
      .includes(:descendant, :hw_nodes, hw_nodes: [:node_ips])
    @params = params_expanded
    @js_data = @ncc_nodes.js_data
  end

  def info
    @ncc_node
  end

  def history
    @prop = params[:prop].to_sym
    @data = @ncc_node.history(@prop)
    @status = @data.size > 0
  end

  def availability
    @status = @ncc_node.availability
  end

  private
    def check_if_ncc_node_exist
      @ncc_node = NccNode.find_by(vid: params[:vid])
      unless @ncc_node
        render nothing: true, status: :bad_request, content_type: "text/html" and return
      end
    end
end

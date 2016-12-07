class NodesController < ApplicationController
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
      ["controller", "action", "format", "_"].include?(key) ||
      false
    end

    # { "search" => "id: 0x1a0e0001, name: Alex" } =>
    # { "vid" => "0x1a0e0001", "name" => "Alex" }
    if params_expanded["search"]
      custom_search = false
      aliases = {
        "id" => "vid",
        "version" => "version_decoded",
        "ver" => "version_decoded",
        "version_hw" => "version",
        "ver_hw" => "version",
       }
      request = params_expanded["search"]

      if request =~ /ids:(?<ids>.*)/
        params_expanded[:vid] = Regexp.last_match[:ids]
          .split(",")
          .map { |id| id.strip }
        custom_search = true
      else
        request.split(",").each do |partial_request|
          if partial_request =~ /^(?<prop>.*):(?<value>.*)$/
            prop = Regexp.last_match[:prop].strip
            prop = aliases[prop] if aliases[prop]
            value = Regexp.last_match[:value].strip

            params_expanded[prop] = value
            custom_search = true
          end
        end
      end
      params_expanded.delete("search") if custom_search
    end

    if params_expanded["search"]
      @search = true
      search_resuls = NccNode.none
      param = params_expanded["search"]
      NccNode.quick_searchable.each do |prop|
        search_method = "where_#{prop}_like".to_sym
        if NccNode.methods.include?(search_method)
          search_resuls = search_resuls |
            NccNode.public_send(search_method, param)
        end
      end
    else
      search_resuls = NccNode.all
      params_expanded.each do |prop, value|
        search_method = "where_#{prop}_like".to_sym
        if NccNode.methods.include?(search_method)
          @search = true
          values = Array(value)
          sub_search_resuls = NccNode.none
          values.each do |value|
            sub_search_resuls = sub_search_resuls |
              NccNode.public_send(search_method, value)
          end
          search_resuls = search_resuls & sub_search_resuls
        end
      end
    end

    per_page = current_user.settings["nodes_per_page"] ||
      Settings.nodes_per_page
    if @search
      # http://stackoverflow.com/a/24448317/6376451
      all_ncc_nodes = NccNode
        .where(id: search_resuls.map(&:id))
        .order(vid: :asc)
      current_ncc_nodes = all_ncc_nodes.where(type: "CurrentNccNode")
      NccNode.per_page = per_page
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
      CurrentNccNode.per_page = per_page
    end

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
    sleep(rand(5)) if Settings.demo_mode == "true"
  end

  private
    def check_if_ncc_node_exist
      @ncc_node = NccNode.find_by(vid: params[:vid])
      render_nothing(:bad_request) unless @ncc_node
    end
end

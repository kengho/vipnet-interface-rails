class NodesController < ApplicationController
  skip_before_action :check_administrator_role
  before_action :check_if_node_exist, only: [:availability, :history, :info]

  def index
    searchable_by = Node.searchable
    query_sql = "("
    query_params = Array.new
    # prepare params for quick search
    if params.key?("search")
      logic = "OR"
      ending = "false"
      params_expanded = Hash.new
      searchable_by.keys.each { |key| params_expanded[key] = params["search"] }
    else
      logic = "AND"
      ending = "true"
      params_expanded = params
    end
    params_expanded.each do |key, param|
      if (searchable_by.key?(key) && param != "" && param)
        prop = searchable_by[key]
        if key == "vipnet_version"
          regexps = Node.vipnet_versions_substitute(param)
          if regexps.class == Array
            query_sql += "("
            regexps.each do |regexp|
              query_sql += "vipnet_version -> 'summary' ILIKE ? OR "
              query_params.push(Node.pg_regexp_adoptation(regexp.source))
            end
            query_sql += "false) #{logic} "
          else
            query_sql += "false #{logic} "
          end
          next
        end
        if prop.class == String
          query_sql += "#{prop} ILIKE ? #{logic} "
        elsif prop.class == Hash
          hash_prop = prop.keys[0]
          key = prop[hash_prop]
          query_sql += "#{hash_prop} -> '#{key}' ILIKE ? #{logic} "
        end
        query_params.push(Node.pg_regexp_adoptation(param))
      end
    end
    query_sql += "#{ending})"

    Node.per_page = current_user.settings["nodes_per_page"] || Settings.nodes_per_page
    if query_sql == "(true)" || query_sql == "(false)"
      @nodes = Node.where("history = 'false'").order(created_first_at: :desc)
      @nodes = @nodes.paginate(page: params[:page])
      @search = false
    else
      @nodes = Node.where(query_sql, *query_params).order(vipnet_id: :asc)
      @nodes_no_history = @nodes.where("history = 'false'")
      @nodes = @nodes_no_history if @nodes_no_history.size > 0
      @size = @nodes.size
      @nodes = @nodes.paginate(page: params[:page])
      @search = true
    end
  end

  respond_to :js
  respond_to :html

  def availability
    @response = {
      parent_id: "#node-#{@node.id}__check-availability"
    }
    availability = @node.availability
    if availability[:errors]
      @response[:status] = false
      @response[:tooltip_text] = t("nodes.fullscreen_tooltip.#{availability[:errors][0][:detail]}.short")
      @response[:fullscreen_tooltip_key] = availability[:errors][0][:detail]
    else
      @response[:status] = availability[:data][:availability]
      @response[:tooltip_text] = t("nodes.row.availability.status_#{availability[:data][:availability]}")
      @response[:fullscreen_tooltip_key] = "node-unavailable" if @response[:status] == false
    end
    respond_with(@response, template: "nodes/row/remote_status_button") and return
  end

  def history
    @response = {
      parent_id: "#node-#{@node.id}__history",
      row_id: "#node-#{@node.id}__row",
      history: true,
    }
    @response[:nodes] = Node.where("vipnet_id = ? AND history = ?", @node.vipnet_id, !@node.history).order(updated_at: :asc)
    if @node.history
      @response[:status] = @response[:nodes].size == 1
      @response[:place] = "before"
      @response[:tooltip_text] = t("nodes.row.history.update_#{@response[:status]}")
    else
      @response[:status] = @response[:nodes].size > 0
      @response[:place] = "after"
      @response[:tooltip_text] = t("nodes.row.history.history_#{@response[:status]}")
    end
    respond_with(@response, template: "nodes/row/remote_status_button") and return
  end

  def info
    @response = {
      parent_id: "#node-#{@node.id}__info",
      name: @node.name,
      vipnet_id: @node.vipnet_id,
      category: @node.category ? t("nodes.row.info.#{@node.category}") : "",
      network: Node.network(@node.vipnet_id),
      ips: @node.ips["summary"] ? @node.ips["summary"] : "",
      vipnet_version: @node.vipnet_version["summary"] ? Node.vipnet_versions_substitute(@node.vipnet_version["summary"]) : "",
      vipnet_version_hw: @node.vipnet_version["summary"] ? @node.vipnet_version["summary"] : "",
      created_first_at: @node.created_first_at,
      deleted_at: @node.deleted_at ? @node.deleted_at : "",
      tooltip_text: t("nodes.row.info.loaded"),
    }
    network = Network.find_by_id(@node.network_id)
    if network
      @response[:network] = "#{@response[:network]} (#{network.name})" if network.name
    else
      Rails.logger.error("Unable to find network '#{@node.network_id}'")
    end
    accessips = @node.accessips(Hash)
    unless accessips.empty?
      tmp_array = Array.new
      @response[:accessips] = String.new
      accessips.each do |vipnet_id, accessip|
        tmp_array.push("#{vipnet_id}→#{accessip}")
      end
      @response[:accessips] = tmp_array.join(", ")
    end
    unless @node.created_first_at_accuracy
      @response[:created_first_at] = "#{t('nodes.row.datetime.before')} #{@response[:created_first_at]}"
    end
    if @node.server_number && @node.abonent_number
      @response[:ncc] = "#{sprintf("%05d", @node.server_number.to_i(16))}→#{sprintf("%05d", @node.abonent_number.to_i(16))}"
    end
    if @node.mftp_server
      @response[:mftp_server] = "#{@node.mftp_server.name} (#{@node.mftp_server.vipnet_id})"
    end
    if @node.history
      @response[:history] =
        "#{t('nodes.row.availability.from')} "\
        "#{@node['created_at'].strftime('%Y-%m-%d %H:%M UTC')} "\
        "#{t('nodes.row.availability.to')} "\
        "#{@node['updated_at'].strftime('%Y-%m-%d %H:%M UTC')} "\
        ""
    else
      @response[:history] = t("nodes.row.info.history_actual_data")
    end
    respond_with(@response, template: "nodes/row/info") and return
  end

  private
    def check_if_node_exist
      @node = Node.find_by_id(params[:node_id])
      render nothing: true, status: 400, content_type: "text/html" and return unless @node
    end

end

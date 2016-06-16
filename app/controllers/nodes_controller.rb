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
        compare_func = "ILIKE"
        compare_func = "=" if Node.columns_hash[key].type == :integer
        if prop.class == String
          query_sql += "#{prop} #{compare_func} ? #{logic} "
        elsif prop.class == Hash
          hash_prop = prop.keys[0]
          key = prop[hash_prop]
          query_sql += "#{hash_prop} -> '#{key}' #{compare_func} ? #{logic} "
        end
        param = Node.pg_regexp_adoptation(param) unless Node.columns_hash[key].type == :integer
        query_params.push(param)
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
    @js = "vipnetInterface.nodesData = {};"
    @nodes.each do |node|
      @js += "vipnetInterface.nodesData['#node-#{node.id}__row'] = {"
      @js += node.data_js
      @js += "};"
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
      row_id: "#node-#{@node.id}__row",
      tooltip_text: t("nodes.row.info.loaded"),
      data: {
        name: @node.name,
        vipnet_id: @node.vipnet_id,
        category: @node.category ? t("nodes.row.info.#{@node.category}") : "",
        network: VipnetParser::network(@node.vipnet_id),
        ip: @node.ip["summary"] ? @node.ip["summary"] : "",
        version: @node.version["summary"] ? Node.vipnet_versions_substitute(@node.version["summary"]) : "",
        version_hw: @node.version["summary"] ? @node.version["summary"] : "",
        created_first_at: @node.created_first_at,
        deleted_at: @node.deleted_at ? @node.deleted_at : "",
        mftp_server: "",
        clients_registred: "",
        ncc: "",
      },
      order: [
        :history,
        :vipnet_id,
        :category,
        :clients_registred,
        :network,
        :ip,
        :accessips,
        :version,
        :version_hw,
        :created_first_at,
        :deleted_at,
        :mftp_server,
        :ncc,
      ],
    }
    network = Network.find_by_id(@node.network_id)
    if network
      @response[:data][:network] = "#{@response[:network]} (#{network.name})" if network.name
    else
      Rails.logger.error("Unable to find network '#{@node.network_id}'")
    end
    accessips = @node.accessips(Hash)
    if !accessips.empty?
      tmp_array = Array.new
      accessips.each do |vipnet_id, accessip|
        tmp_array.push("#{vipnet_id}→#{accessip}")
      end
      @response[:data][:accessips] = tmp_array.join(", ")
    else
      @response[:data][:accessips] = ""
    end
    unless @node.created_first_at_accuracy
      @response[:data][:created_first_at] = "#{t('nodes.row.datetime.before')} #{@response[:data][:created_first_at]}"
    end
    if @node.server_number && @node.abonent_number
      @response[:data][:ncc] = "#{sprintf("%05d", @node.server_number.to_i(16))}→#{sprintf("%05d", @node.abonent_number.to_i(16))}"
    end
    if @node.mftp_server
      vipnet_id = @node.mftp_server.vipnet_id
      mftp_server_name = @node.mftp_server.name
      @response[:data][:mftp_server] = "<a href='?vipnet_id=#{vipnet_id}'>#{vipnet_id} #{mftp_server_name}</a>"
    elsif @node.mftp_server == false
      criteria = { server_number: @node.server_number, network_id: @node.network_id, category: "client", history: false }
      query_sql = criteria.map { |prop, value| "#{prop.to_s} = '#{value}'" }.join(" AND ")
      query_get = criteria.map { |prop, value| "#{prop.to_s}=#{value}" }.join("&")
      clients_registred = Node.where("#{query_sql}")
      if clients_registred.size > 0
        @response[:data][:clients_registred] = "<a href='?#{query_get}'>#{clients_registred.size}</a>"
      else
        @response[:data][:clients_registred] = "0"
      end
    end
    if @node.history
      @response[:data][:history] =
        "#{t('nodes.row.availability.from')} "\
        "#{@node['created_at'].strftime('%Y-%m-%d %H:%M UTC')} "\
        "#{t('nodes.row.availability.to')} "\
        "#{@node['updated_at'].strftime('%Y-%m-%d %H:%M UTC')} "\
        ""
    else
      @response[:data][:history] = t("nodes.row.info.history_actual_data")
    end
    respond_with(@response, template: "nodes/row/info") and return
  end

  private
    def check_if_node_exist
      @node = Node.find_by_id(params[:node_id])
      render nothing: true, status: 400, content_type: "text/html" and return unless @node
    end
end

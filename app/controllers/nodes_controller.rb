class NodesController < ApplicationController
  skip_before_action :check_administrator_role

  def index
    # params:
    # {"name"=>"co", "vipnet_version"=>"3.0-671"}
    # query_sql:
    # "name ILIKE ? AND vipnet_version -> 'summary' ILIKE ?"
    # query_params:
    # ["%co%", "%3.0-671%"]
    searchable_by = Node.searchable
    query_sql = String.new
    query_params = Array.new
    params.each do |key, param|
      if (searchable_by.key?(key) && param != "" && param)
        # _ => \_ (search exactly "_")
        param = param.gsub("_","\\_")
        # .* => % (like regexp)
        param = param.gsub(".*","%")
        # . => _ (like regexp)
        param = param.gsub(".","_")
        prop = searchable_by[key]
        query_sql += " AND " if query_sql.size > 0
        if prop.class == String
          query_sql += "#{prop} ILIKE ?"
        end
        if prop.class == Hash
          hash_prop = prop.keys[0]
          key = prop[hash_prop]
          query_sql += "#{hash_prop} -> '#{key}' ILIKE ?"
        end
        query_params.push("%" + param + "%")
      end
    end

    if query_sql.empty?
      @nodes = Node.where("history = 'false'")
      @size_all = @nodes.size
      @nodes = @nodes.paginate(page: params[:page], per_page: Settings.nodes_per_page)
      @search = false
    else
      @nodes = Node.where(query_sql, *query_params)
      nodes_no_history = @nodes.where("history = 'false'")
      @size_all = @nodes.size
      @size_no_history = nodes_no_history.size
      @nodes = @nodes.paginate(page: params[:page], per_page: Settings.nodes_per_page)
      @search = true
    end

  end

  respond_to :js
  respond_to :html

  def availability
    @node = Node.find_by_id(params[:node_id])
    @response = {
      node: @node,
      div_suffix: "check-availability",
    }
    if Iplirconf.all.size == 0
      @response[:status] = false
      @response[:reason] = "no accessips"
    else
      availability = @node.availability
      if availability[:errors]
        @response[:status] = false
        @response[:reason] = availability[:errors][0][:detail]
      else
        @response[:status] = availability[:data][:availability]
      end
    end
    respond_with(@response, template: "nodes/row/remote_status_button") and return
  end

  def history
    @node = Node.find_by_id(params[:node_id])
    @response = {
      node: @node,
      div_suffix: "history"
    }
    @response[:args] = Node.where("vipnet_id = '#{@node.vipnet_id}' AND history = '#{!@node.history}'").reorder("updated_at ASC")
    if @node.history
      @response[:status] = @response[:args].size == 1
      @response[:place] = "before"
    else
      @response[:status] = @response[:args].size > 0
      @response[:place] = "after"
    end
    respond_with(@response, template: "nodes/row/remote_status_button") and return
  end

  private
    def node_params
      params.require(:node).permit(:vipnet_id, :name)
    end
end

module NodesHelper
  def column_order
    always_visible = true
    visible_if_iplirconf_api_enabled = Settings.iplirconf_api_enabled == "true"
    visible_if_ticket_api_enabled = Settings.ticket_api_enabled == "true"
    [
      # erb, prop, visibility
      ["space",         nil,                          always_visible],
      ["remote_button", :availability,                visible_if_iplirconf_api_enabled],
      ["cell",          :vid,                         always_visible],
      ["remote_button", :info,                        always_visible],
      ["remote_button", [:history, :name],            always_visible],
      ["cell",          :name,                        always_visible],
      ["remote_button", [:history, :version_decoded], visible_if_iplirconf_api_enabled],
      ["cell",          :version_decoded,             visible_if_iplirconf_api_enabled],
      ["cell",          :creation_date,               always_visible],
      ["cell",          :ticket,                      visible_if_ticket_api_enabled],
      ["space",         :history_close_button,        always_visible],
    ]
  end

  def column_erbs(place)
    column_erbs = []
    column_order.each do |order|
      erb, prop, visibility = order
      if visibility
        if lookup_context.template_exists?("nodes/#{place}/_#{erb}")
          params = erb_params(erb, prop)
          column_erbs.push(erb: "nodes/#{place}/#{erb}", params: params)
        else
          column_erbs.push(erb: "nodes/space")
        end
      end
    end

    column_erbs
  end

  def erb_params(erb, prop)
    if prop.class == Array
      prop, variant = prop
    else
      prop = prop
    end

    case erb
    when "cell"
      { prop: prop }

    when "remote_button"

      case prop
      when :availability
        case @ncc_node.status
        when :ok
          {
            icon: i("nodes.row.remote_button.availability"),
            t: t("nodes.row.remote_button.availability.label"),
            action_name: "availability",
            action_prop: nil,
            color: "primary",
            disabled: false,
            additional_td_classes: ["td--show-onhover", "td--button"],
          }

        when :deleted
          {
            icon: i("nodes.row.remote_button.deleted"),
            t: "#{t('nodes.row.status.deleted')} #{prop_view_datetime(@ncc_node.deletion_date, :short)}",
            action_name: nil,
            action_prop: nil,
            color: "accent",
            disabled: true,
            additional_td_classes: ["td--button", "td--hoverable-tooltip"],
          }

        when :disabled
          {
            icon: i("nodes.row.remote_button.disabled"),
            t: t("nodes.row.status.disabled"),
            action_name: nil,
            action_prop: nil,
            color: "accent",
            disabled: true,
            additional_td_classes: ["td--button"],
          }
        end

      when :info
        {
          icon: i("nodes.row.remote_button.info"),
          t: t("nodes.row.remote_button.info.label"),
          action_name: "info",
          action_prop: nil,
          color: "primary",
          disabled: false,
          additional_td_classes: ["td--show-onhover", "td--button"],
        }

      when :history
        {
          icon: i("nodes.row.remote_button.history"),
          t: t("nodes.row.remote_button.history.label"),
          action_name: "history",
          action_prop: variant,
          color: "gray",
          disabled: false,
          additional_td_classes: ["td--show-onhover", "td--button", "td--small-icon-right"],
        }
      end
    end
  end

  def history_prop(ncc_node)
    NccNode.props_from_nodename.each do |prop|
      return prop if ncc_node[prop]
    end

    if ncc_node.hw_nodes
      hw_node = ncc_node.hw_nodes.first
      HwNode.props_from_iplirconf.each do |prop|
        return prop if hw_node[prop]
      end
    end
  end
end

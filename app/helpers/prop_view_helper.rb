module PropViewHelper
  def prop_view(ncc_node, prop, detalization = :short)
    case prop

    when :vid
      ncc_node.vid

    when :name
      ncc_node.name

    when :deletion_date
      prop_view_datetime(ncc_node.deletion_date, detalization)

    when :creation_date
      creation_date_view = prop_view_datetime(ncc_node.creation_date, detalization)
      if ncc_node.creation_date_accuracy
        creation_date_view
      else
        case detalization
        when :short
          "<span class=\"nodes__link--hover nodes__hover-for-tooltip\">"\
            "#{I18n.t('nodes.row.creation_date.before')}"\
          "</span>"\
          "<div class=\"nodes__tooltip created-at__tooltip\">"\
            "#{t('nodes.row.creation_date.unknown_date')}"\
          "</div>&nbsp;"\
          "#{creation_date_view}"
        when :long
          "#{I18n.t('nodes.row.creation_date.before')} #{creation_date_view}"
        end
      end

    when :ip
      ips = []
      ncc_node.hw_nodes.each do |hw_node|
        hw_node.node_ips.each do |node_ip|
          ips.push(IPv4::ip(node_ip.u32))
        end
      end
      ips.join(", ")

    when :accessip
      accessips = []
      ncc_node.hw_nodes.each do |hw_node|
        accessips.push(
          "<a href='?vid=#{hw_node.coordinator.vid}'>#{hw_node.coordinator.vid}</a>"\
          "&nbsp;→&nbsp;"\
          "#{hw_node.accessip}"
        )
      end
      accessips.join(", ")

    when :version_decoded
      prop_view_version(ncc_node, :version_decoded)

    when :version
      prop_view_version(ncc_node, :version)

    when :ticket
      tickets = ncc_node.tickets
      if tickets.any?
        links = []
        tickets.each do |ticket|
          href = ticket.ticket_system.url_template.gsub("{id}", ticket.ticket_id.to_s)
          links.push("<a href=#{href}>#{ticket.ticket_id.to_s}</a>")
        end

        case detalization
        when :short
          if links.size == 1
            links.first
          elsif links.size > 1
            html = ""
            html += "<div name=\"multi--hover\">"
            html += links[0]
            html += "</div>"
            html += "<div name=\"multi--list\">"
            links.each_with_index do |link, i|
              next if i == 0
              html += link + "<br>"
            end
            html += "</div>"
            html
          end
        when :long
          links.join(", ")
        end
      end

    when :enabled
      I18n.t("boolean.#{ncc_node.enabled}")

    when :network
      network_vid = ncc_node.network.network_vid
      network_name = ncc_node.network.name
      "#{network_vid}#{network_name ? ' (' + network_name + ')' : ''}"

    when :category
      I18n.t("nodes.row.info.categories.#{ncc_node.category}")

    when :ncc
      if ncc_node.server_number && ncc_node.abonent_number
        server_number_normal = sprintf("%05d", ncc_node.server_number.to_i(16))
        abonent_number_normal = sprintf("%05d", ncc_node.abonent_number.to_i(16))
        "#{server_number_normal}&nbsp;→&nbsp;#{abonent_number_normal}"
      end

    when :clients_registred
      if ncc_node.category == "server"
        clients_registred = NccNode.where_mftp_server_vid_like(ncc_node.vid)
        "<a href='?mftp_server_vid=#{ncc_node.vid}'>#{clients_registred.size.to_s}</a>" if clients_registred
      end

    when :mftp_server
      mftp_server = ncc_node.mftp_server
      "<a href='?vid=#{mftp_server.vid}'>#{mftp_server.vid}</a>" if mftp_server

    end
  end

  def prop_view_version(ncc_node, field)
    tmp = []
    ncc_node.hw_nodes.each { |hw_node| tmp.push(hw_node[field]) }
    tmp.sort!.uniq!
    if tmp.size == 1
      tmp.first
    elsif tmp.size > 1
      "?"
    end
  end

  def prop_view_datetime(datetime, detalization)
    if datetime.class == ActiveSupport::TimeWithZone
      case detalization
      when :short
        datetime.strftime("%Y-%m-%d")
      when :long
        datetime.strftime("%Y-%m-%d %H:%M UTC")
      end
    end
  end
end

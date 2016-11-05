module Nodes::RowHelper
  def prop_view(prop, detalization = :short)
    case prop

    when :vid
      view = @ncc_node.vid

    when :name
      view = @ncc_node.name

    when :creation_date
      creation_date_view = prop_view_datetime(@ncc_node.creation_date, detalization)
      if @ncc_node.creation_date_accuracy
        view = creation_date_view
      else
        case detalization
        when :short
          view = render "nodes/row/creation_date", creation_date: creation_date_view
        when :long
          view = "#{I18n.t('nodes.row.creation_date.before')} #{creation_date_view}"
        end
      end

    when :deletion_date
      view = prop_view_datetime(@ncc_node.deletion_date, detalization)

    when :ip
      ips = []
      @ncc_node.hw_nodes.each do |hw_node|
        hw_node.node_ips.each { |node_ip| ips.push(node_ip.u32) }
      end
      view = ips.sort.map {|ip| IPv4::ip(ip) }.join(", ")

    when :accessip
      accessips = []
      @ncc_node.hw_nodes.each do |hw_node|
        accessips.push(
          "<a href='?vid=#{hw_node.coordinator.vid}'>#{hw_node.coordinator.vid}</a>"\
          "&nbsp;→&nbsp;"\
          "#{hw_node.accessip}"
        )
      end
      view = accessips.join(", ")

    when :version_decoded
      view = prop_view_version(:version_decoded, detalization)

    when :version
      view = prop_view_version(:version, detalization)

    when :ticket
      tickets = @ncc_node.tickets
      if tickets.any?
        links = []
        tickets.each do |ticket|
          href = ticket.ticket_system.url_template.gsub("{id}", ticket.ticket_id.to_s)
          links.push(href: href, text: ticket.ticket_id.to_s)
        end

        case detalization
        when :short
          view = render "nodes/row/ticket", links: links
        when :long
          htmls = []
          links.each do |link|
            htmls.push(render "shared/link", link)
          end
          view = htmls.join(", ")
        end
      end

    when :enabled
      view = I18n.t("boolean.#{@ncc_node.enabled}")

    when :network
      network_vid = @ncc_node.network.network_vid
      network_name = @ncc_node.network.name
      view = "#{network_vid}#{network_name ? ' (' + network_name + ')' : ''}"

    when :category
      view = I18n.t("nodes.row.remote_button.info.categories.#{@ncc_node.category}")

    when :ncc
      if @ncc_node.server_number && @ncc_node.abonent_number
        server_number_normal = sprintf("%05d", @ncc_node.server_number.to_i(16))
        abonent_number_normal = sprintf("%05d", @ncc_node.abonent_number.to_i(16))
        view = "#{server_number_normal}&nbsp;→&nbsp;#{abonent_number_normal}"
      end

    when :clients_registered
      if @ncc_node.category == "server"
        clients_registered = NccNode.where_mftp_server_vid_like(@ncc_node.vid)
        if clients_registered
          view = render "shared/link", {
            href: "?mftp_server_vid=#{@ncc_node.vid}",
            text: clients_registered.size.to_s,
          }
        end
      end

    when :mftp_server
      mftp_server = @ncc_node.mftp_server
      if mftp_server
        view = render "shared/link", {
          href: "?vid=#{mftp_server.vid}",
          text: mftp_server.vid,
        }
      end
    end

    return view || ""
  end

  def prop_view_version(field, detalization = :short)
    case detalization
    when :short
      @ncc_node.most_likely(:version_decoded)
    when :long
      long_versions = []
      @ncc_node.hw_nodes.each do |hw_node|
        long_versions.push(
          "<a href='?vid=#{hw_node.coordinator.vid}'>#{hw_node.coordinator.vid}</a>"\
          "&nbsp;→&nbsp;"\
          "#{hw_node[field]}"
        )
      end
      long_versions.join(", ")
    end
  end

  def prop_view_datetime(datetime, detalization = :short)
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

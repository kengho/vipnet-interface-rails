module PropViewHelper
  def prop_view(node, prop, detalization = :short)
    case prop

    when :name
      node.name

    when :network_id
      network = Network.find_by_id(node.network_id)
      "#{network.network_vid}#{network.name ? ' (' + network.name + ')' : ''}"

    when :vid
      node.vid

    when :enabled
      I18n.t("boolean.#{node.enabled}")

    when :ip
      case detalization
      when :short
        tmp_arr = []
        node.ip.each { |coord_vid, ips| tmp_arr += eval(ips) }
        tmp_arr.sort.uniq.join(", ")
      when :long
        prop_view_hstore(node, :ip)
      end

    when :accessip
      prop_view_hstore(node, :accessip)

    when :version
      prop_view_hstore(node, :version)

    when :version_decoded
      case detalization
      when :short
        tmp_arr = []
        node.version_decoded.each { |_, version| tmp_arr.push(version) }
        tmp_arr.sort!.uniq!
        if tmp_arr.size == 0
          ""
        elsif tmp_arr.size == 1
          tmp_arr.first
        elsif tmp_arr.size > 1
          "?"
        end
      when :long
        prop_view_hstore(node, :version_decoded)
      end

    when :deletion_date
      prop_view_datetime(node.deletion_date, detalization)

    when :creation_date
      creation_date_view = prop_view_datetime(node.creation_date, detalization)
      if node.creation_date_accuracy
        creation_date_view
      else
        "#{I18n.t('nodes.row.creation_date.before')} #{creation_date_view}"
      end

    when :category
      I18n.t("nodes.row.info.categories.#{node.category}")

    when :ncc
      if node.server_number && node.abonent_number
        "#{sprintf("%05d", node.server_number.to_i(16))}&nbsp;→&nbsp;#{sprintf("%05d", node.abonent_number.to_i(16))}"
      else
        ""
      end

    when :ticket
      if node.ticket == {}
        ""
      else
        links = []
        node.ticket.each do |url_template, ids|
          eval(ids).each do |id|
            href = url_template.gsub("{id}", id.to_s)
            links.push("<a href=#{href}>#{id.to_s}</a>")
          end
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

    else
      ""
    end
  end

  def prop_view_hstore(node, prop)
    tmp_arr = []
    node[prop].each do |coord_vid, value|
      if value =~ /^\[.*\]$/
        tmp_arr.push("#{coord_vid}&nbsp;→&nbsp;\"#{eval(value).sort.uniq.join(', ')}\"")
      else
        tmp_arr.push("#{coord_vid}&nbsp;→&nbsp;\"#{value}\"")
      end
    end
    tmp_arr.join(", ").gsub("-", "&#8209;")
  end

  def prop_view_datetime(datetime, detalization)
    if datetime.class == ActiveSupport::TimeWithZone
      case detalization
      when :short
        datetime.strftime("%Y-%m-%d")
      when :long
        datetime.strftime("%Y-%m-%d %H:%M UTC")
      end
    else
      ""
    end
  end
end

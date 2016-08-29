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
      prop_view_hstore(node, :ip)

    when :accessip
      prop_view_hstore(node, :accessip)

    when :version
      prop_view_hstore(node, :version)

    when :version_decoded
      prop_view_hstore(node, :version_decoded)

    when :deletion_date
      if node[prop].class == ActiveSupport::TimeWithZone
        node[prop].strftime("%Y-%m-%d %H:%M UTC")
      else
        ""
      end

    when :creation_date
      deletion_date_view = prop_view(node, :deletion_date)
      if node.creation_date_accuracy
        deletion_date_view
      else
        "#{I18n.t('nodes.row.creation_date.before')} #{deletion_date_view}"
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
        links.join(", ")
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
end

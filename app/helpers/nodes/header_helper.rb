module Nodes::HeaderHelper
  def js_subtitle
    if @search
      @subtitle = "#{t('nodes.header.search_results_subtitle')} (#{@size})"
    else
      @subtitle = t("nodes.header.default_nodes_subtitle")
    end
  end

  def nav_buttons
    always_visible = true
    # [
    #   id,
    #   props,
    #   icon,
    #   label,
    #   visibility
    # ]
    [
      [
        "header__settings",
        { "href" => "/settings#general" },
        i("nodes.header.nav.settings"),
        t(".settings"),
        current_user.role == "administrator",
      ],
      [
        "header__support",
        { "href" => "mailto: #{Settings.support_email}" },
        "feedback",
        t(".support"),
        !Settings.support_email.empty?,
      ],
      [
        "header__profile",
        { "href" => url_for(edit_user_path(current_user)) },
        i("nodes.header.nav.profile"),
        t(".profile"),
        always_visible,
      ],
      [
        "header__exit",
        {
          "href" => url_for(sign_out_path),
          "rel" => "nofollow",
          "data-method" => "delete",
        },
        i("nodes.header.nav.exit"),
        t(".exit"),
        always_visible,
      ],
    ]
  end
end

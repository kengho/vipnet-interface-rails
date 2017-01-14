module ApplicationHelper
  # http://stackoverflow.com/questions/2701749/rails-internationalization-of-javascript-strings
  def current_translations
    @translations ||= I18n.backend.send(:translations)
    @translations[I18n.locale].with_indifferent_access
  end

  def page_title
    title_locale_path = "#{params[:controller].gsub("/", ".")}.#{params[:action]}.title"
    title = t(title_locale_path)
    if title.class == String
      return t(title_locale_path)
    else
      return t("default.title")
    end
  end

  # https://gist.github.com/jeroenr/3142686
  class LinkRenderer < WillPaginate::ActionView::LinkRenderer
    def link(text, target, attributes = {})
      attributes["data-remote"] = true
      super
    end
  end

  def paginate(collection, params = {})
    will_paginate(collection, params.merge(renderer: ApplicationHelper::LinkRenderer))
  end

  def i(path)
    icons = YAML.load_file(Rails.root.join("config/icons.yml"))
    icon = icons.clone
    path.split(".").each do |turn|
      icon = icon[turn]
    end

    icon
  end
end

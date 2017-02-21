module ApplicationHelper
  # http://stackoverflow.com/questions/2701749/rails-internationalization-of-javascript-strings
  def current_translations
    @translations ||= I18n.backend.send(:translations)
    @translations[I18n.locale].with_indifferent_access
  end

  def page_title
    title_locale_path = "#{params[:controller].tr('/', '.')}"\
                        ".#{params[:action]}.title"
    title = t(title_locale_path)
    return t("default.title") unless title.class == String

    title
  end

  # https://gist.github.com/jeroenr/3142686
  class LinkRenderer < WillPaginate::ActionView::LinkRenderer
    def link(text, target, attributes = {})
      attributes["data-remote"] = true
      super
    end
  end

  def paginate(collection, params = {})
    paginate_params = params.merge(renderer: ApplicationHelper::LinkRenderer)
    will_paginate(collection, paginate_params)
  end

  def i(path)
    icons = YAML.load_file(Rails.root.join("config", "icons.yml"))
    icon = icons.clone
    path.split(".").each { |turn| icon = icon[turn] }

    icon
  end
end

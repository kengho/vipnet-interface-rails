module TitleHelper
  def page_title
    title_locale_path = "#{params[:controller].gsub("/", ".")}.#{params[:action]}.title"
    title = t(title_locale_path)
    if title.class == String
      t(title_locale_path)
    else
      t("default.title")
    end
  end
end

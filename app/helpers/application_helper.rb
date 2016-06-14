module ApplicationHelper
  # http://stackoverflow.com/questions/2701749/rails-internationalization-of-javascript-strings
  def current_translations
    @translations ||= I18n.backend.send(:translations)
    @translations[I18n.locale].with_indifferent_access
  end

  def self.available_locales
    (I18n.available_locales - [:"zh-CN"] - [:"zh-TW"]).map(&:to_s)
  end
end

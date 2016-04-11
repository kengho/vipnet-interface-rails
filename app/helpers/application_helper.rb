module ApplicationHelper
  # http://stackoverflow.com/questions/2701749/rails-internationalization-of-javascript-strings
  def current_translations
    @translations ||= I18n.backend.send(:translations)
    @translations[I18n.locale].with_indifferent_access
  end
end

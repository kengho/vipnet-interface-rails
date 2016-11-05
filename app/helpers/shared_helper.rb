module SharedHelper
  def user_settings_params
    {
      "data-user-settings": "true",
      "data-user-url": url_for(current_user),
    }
  end
end

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  protect_from_forgery with: :exception unless Rails.env.test?
  before_action :set_locale
  before_action :authenticate_user

  helper_method :current_user_session, :current_user, :current

  private
    def current(settings)
      system_settings =
         Settings[settings] ||
         Settings.values[settings][:default_value] ||
         true
      if current_user
        current_settings =
          current_user.settings[settings] ||
          system_settings ||
          true
      else
        current_settings = system_settings
      end
      current_settings
    end

    def set_locale
      I18n.locale = current("locale")
    end

    def check_administrator_role
      unless current_user.role == "administrator"
        redirect_to sign_in_path
      end
    end

    def current_user_session
      return @current_user_session if defined?(@current_user_session)
      @current_user_session = UserSession.find
    end

    def current_user
      return @current_user if defined?(@current_user)
      @current_user = current_user_session && current_user_session.user
    end

    def authenticate_user
      unless current_user
        redirect_to sign_in_path
      end
    end

    respond_to :js

    def check_demo_mode
      render "shared/unavailable_in_demo_mode" and return if Settings.demo_mode == "true"
    end
end

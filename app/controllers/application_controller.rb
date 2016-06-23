class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :set_locale
  before_action :authenticate_user
  before_action :check_administrator_role

  helper_method :current_user_session, :current_user

  private
    def set_locale
      if current_user
        I18n.locale = current_user.settings.locale
      else
        I18n.locale = I18n.default_locale
      end
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
end

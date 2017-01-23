class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  protect_from_forgery with: :exception unless Rails.env.test?
  before_action :set_locale
  before_action :authenticate_user

  helper_method :current_user_session, :current_user, :current

  private

    def current(settings)
      system_settings = Settings[settings] ||
                        Settings.values[settings][:default_value]

      if current_user
        current_user.settings[settings] || system_settings
      else
        system_settings
      end
    end

    def set_locale
      I18n.locale = current("locale")
    end

    def check_administrator_role
      redirect_to sign_in_path unless current_user.role == "administrator"
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
      redirect_to sign_in_path unless current_user
    end

    def render_nothing(status)
      render body: nil, status: status, content_type: "text/html"
    end

    def clear_params(params)
      clear_params = params.to_unsafe_h.clone
      clear_params.each_value(&:strip!)

      # "_" is "cache buster".
      # http://stackoverflow.com/a/5355707/6376451
      clear_params.reject! do |key, value|
        value.empty? || %w(controller action format _).include?(key)
      end

      clear_params
    end

    def expand_params(params)
      expanded_params = params.clone

      if expanded_params["search"]
        custom_search = false
        aliases = {
          "id" => "vid",
          "version" => "version_decoded",
          "ver" => "version_decoded",
          "version_hw" => "version",
          "ver_hw" => "version",
        }
        request = expanded_params["search"]

        if request =~ /ids:(?<ids>.*)/
          expanded_params[:vid] = Regexp
                                    .last_match(:ids)
                                    .split(",")
                                    .map(&:strip)
          custom_search = true
        else
          request.split(",").each do |partial_request|
            next unless partial_request =~ /^(?<prop>.+):(?<value>.+)$/

            prop = Regexp.last_match(:prop).strip
            prop = aliases[prop] if aliases[prop]
            value = Regexp.last_match(:value).strip

            expanded_params[prop] = value
            custom_search = true
          end
        end
        expanded_params.delete("search") if custom_search
      end

      expanded_params
    end

    respond_to :js

    def check_demo_mode
      demo_mode = Settings.demo_mode == "true"
      render "shared/unavailable_in_demo_mode" and return if demo_mode
    end
end

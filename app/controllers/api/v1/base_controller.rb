class Api::V1::BaseController < ActionController::Base
  OK_RESPONSE = "ok".freeze
  ERROR_RESPONSE = "error".freeze

  # Prevent CSRF attacks by raising an exception.
  protect_from_forgery with: :null_session

  before_action :check_if_api_enabled
  before_action :destroy_session
  before_action :authenticate

  private

    def render_nothing(status)
      render body: nil, status: status, content_type: "text/html"
    end

    def check_if_api_enabled
      disable_api = Settings.disable_api == "true"
      render_nothing(:service_unavailable) and return if disable_api
    end

    def destroy_session
      request.session_options[:skip] = true
    end

    def authenticate
      actions_get = {
        "api/v1/nodes" => ["index"],
        "api/v1/accessips" => ["index"],
        "api/v1/availability" => ["index"],
      }

      actions_post = {
        "api/v1/iplirconfs" => {
          actions: ["create"],
          token_name: "POST_HW_TOKEN",
        },
        "api/v1/messages" => {
          actions: ["create"],
          token_name: "POST_ADMINISTRATOR_TOKEN",
        },
        "api/v1/nodenames" => {
          actions: ["create"],
          token_name: "POST_ADMINISTRATOR_TOKEN",
        },
        "api/v1/tickets" => {
          actions: ["create"],
          token_name: "POST_TICKETS_TOKEN",
        },
      }

      if actions_get.key?(params[:controller])
        action_is_valid = actions_get[params[:controller]]
                            .include?(params[:action])
        render_nothing(:unauthorized) and return unless action_is_valid
        render_nothing(:unauthorized) and return unless params[:token]
        token_is_valid = ActiveSupport::SecurityUtils.secure_compare(
          params[:token],
          ENV["GET_INFORMATION_TOKEN"],
        )
        render_nothing(:unauthorized) and return unless token_is_valid

        true
      elsif actions_post.key?(params[:controller])
        action_is_valid = actions_post[params[:controller]][:actions]
                            .include?(params[:action])
        render_nothing(:unauthorized) and return unless action_is_valid
        authenticate_or_request_with_http_token do |token, _|
          token_is_valid = ActiveSupport::SecurityUtils.secure_compare(
            token,
            ENV[actions_post[params[:controller]][:token_name]],
          )
          render_nothing(:unauthorized) and return unless token_is_valid

          true
        end
      end
    end

    def minutes_after_latest_update(*tables)
      latest_element = lambda do |table|
        table
          .classify
          .constantize
          .reorder(updated_at: :desc)
          .first
      end

      latest_update_date = tables
                             .map { |table| latest_element.call(table) }
                             .reject(&:!)
                             .map(&:updated_at)
                             .sort
                             .last

      (DateTime.current - latest_update_date.to_datetime) * 1.day / 1.minute
    end
end

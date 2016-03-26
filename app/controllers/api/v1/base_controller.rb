class Api::V1::BaseController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  before_action :destroy_session
  before_action :authenticate

  private
    def destroy_session
      request.session_options[:skip] = true
    end

    def authenticate
      actions_get = {
        "api/v1/accessips" => ["index"],
        "api/v1/nodes" => ["index"],
      }

      actions_post = {
        "api/v1/ipliconfs" => {
          :actions => ["create"],
          :token_name => "POST_HW_TOKEN"
        },
        "api/v1/messages" => {
          :actions => ["create"],
          :token_name => "POST_ADMINISTRATOR_TOKEN"
        },
        "api/v1/nodenames" => {
          :actions => ["create"],
          :token_name => "POST_ADMINISTRATOR_TOKEN"
        },
      }

      if actions_get.key?(params[:controller])
        if actions_get[params[:controller]].include?(params[:action])
          unless ActiveSupport::SecurityUtils.secure_compare(params[:token], ENV["GET_INFORMATION_TOKEN"])
            render nothing: true, status: 401, content_type: "text/html"
          end
        end
      end
      
      if actions_post.key?(params[:controller])
        if actions_post[params[:controller]][:actions].include?(params[:action])
          authenticate_or_request_with_http_token do |token, _|
            unless ActiveSupport::SecurityUtils.secure_compare(token, ENV[actions_post[params[:controller]][:token_name]])
              render nothing: true, status: 401, content_type: "text/html"
            else
              true
            end
          end
        end
      end

    end

end

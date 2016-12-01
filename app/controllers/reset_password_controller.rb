class ResetPasswordController < ApplicationController
  skip_before_action :authenticate_user, :check_administrator_role
  before_action :check_demo_mode
  
  respond_to :js

  def index
    if params[:email]
      send_email
    elsif params[:token]
      reset_password
    end
  end

  def send_email
    user = User.find_by(email: params[:email])
    if user
      user.reset_perishable_token!
      @email = {
        to: params[:email],
        template: :reset_password,
        params: {
          token: user.perishable_token,
        },
      }

      UserMailer.send_email(@email).deliver_now
    end

    render "send_email"
  end

  def reset_password
    user = User.find_using_perishable_token(params[:token])
    if user
      UserSession.create(user)
      user.update_attribute(:reset_password_allowed, true)
      redirect_to edit_user_url(user)
    else
      render nothing: true, status: :unauthorized, content_type: "text/html" and return
    end
  end
end

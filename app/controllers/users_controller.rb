class UsersController < ApplicationController
  skip_before_action :check_administrator_role

  def edit
    @user = current_user
  end

  def destroy
    user = User.find(params[:id])
    if user.destroy
      flash[:notice] = "user destroyed"
    else
      flash[:notice] = "error destroying user"
    end
    redirect_to "/settings#users"
  end

  def update
    params.each do |param, value|
      if User.settings.include?(param)
        current_user.settings[param] = value
      end
    end
    unless current_user.save
      flash[:notice] = "error saving user settings"
    else
      flash[:notice] = "user settings saved"
    end
    if params["user_session"]
      if current_user.valid_password?(params["user_session"]["current_password"])
        current_user.password = params["user_session"]["password"]
        current_user.password_confirmation = params["user_session"]["password_confirmation"]
        unless current_user.save
          flash[:error] = "error confirmation passwords"
        else
          flash[:success] = "password successfully changed"
          redirect_to "/nodes"
        end
      else
        flash[:error] = "error validating password"
      end
    end
    redirect_to edit_user_path(current_user)
  end

  private
    def users_params
      params.require(:user).permit(:email, :password, :password_confirmation)
    end
end

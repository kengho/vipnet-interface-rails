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
    # user additional settings
    params.each do |param, value|
      # save settings if there are no accepted values or if passed value is in it
      corresponding_settings = User.settings[param.to_sym]
      if corresponding_settings
        accepted_values = corresponding_settings[:accepted_values]
        if !accepted_values
          current_user.settings[param] = value
        elsif accepted_values.include?(value)
          current_user.settings[param] = value
        end
      end
    end
    if current_user.save
      flash[:notice] = "user settings saved"
    else
      flash[:notice] = "error saving user settings"
    end
    # user auth settings
    if params["user_session"]
      if current_user.valid_password?(params["user_session"]["current_password"])
        current_user.password = params["user_session"]["password"]
        current_user.password_confirmation = params["user_session"]["password_confirmation"]
        if current_user.save
          flash[:success] = "password successfully changed"
          redirect_to "/nodes"
        else
          flash[:error] = "error confirmation password"
        end
      else
        flash[:error] = "error validating password"
      end
    end

    if params["redirect_to"]
      redirect_to params["redirect_to"]
    else
      redirect_to edit_user_path(current_user)
    end
  end

  private
    def users_params
      params.require(:user).permit(:email, :password, :password_confirmation)
    end
end

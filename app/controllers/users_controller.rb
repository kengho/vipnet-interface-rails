class UsersController < ApplicationController
  skip_before_action :check_administrator_role

  def edit
    @user = current_user
  end

  def destroy
    user = User.find_by(id: params[:id])
    if user
      if user.destroy
        flash[:notice] = :user_destroyed
      else
        flash[:notice] = :error_destroying_user
      end
    else
      render nothing: true, status: :bad_request, content_type: "text/html" and return
    end
    redirect_to "/settings#users"
  end

  respond_to :js

  def update
    if current_user.id.to_s != params["id"]
      render nothing: true, status: :unauthorized, content_type: "text/html" and return
    end

    # additional user settings
    name = params["name"]
    corresponding_settings = Settings.values[name]
    if corresponding_settings
      value = params["value"]
      accepted_values = corresponding_settings[:accepted_values]
      if !accepted_values
        current_user.settings[name] = value
      elsif accepted_values.include?(value)
        current_user.settings[name] = value
      end
      if current_user.save
        @response = :user_settings_saved
      else
        @response = :error_saving_user_settings
      end
    end

    if params["user_session"]
      if current_user.reset_password_allowed
        password_is_valid = true
      elsif current_user.valid_password?(params["user_session"]["current_password"])
        password_is_valid = true
      else
        password_is_valid = false
      end

      if password_is_valid
        if params["user_session"]["password"].to_s != params["user_session"]["password_confirmation"].to_s
          @response = :error_confirmation_password
        else
          current_user.password = params["user_session"]["password"]
          current_user.password_confirmation = params["user_session"]["password_confirmation"]
          if current_user.changed? && current_user.save
            current_user.update_attribute(:reset_password_allowed, nil)
            @response = :password_successfully_changed
          else
            @response = :error_changing_password
          end
        end
      else
        @response = :error_validating_password
      end
    end

    respond_with(@response, template: "shared/user") and return
  end
end

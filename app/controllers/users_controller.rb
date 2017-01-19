class UsersController < ApplicationController
  before_action :check_demo_mode, except: :edit

  def edit
    @user = current_user
  end

  respond_to :js

  def destroy
    user = User.find_by(id: params[:id])
    render_nothing(:bad_request) unless user
    if user.destroy
      flash[:notice] = :user_destroyed
    else
      flash[:notice] = :error_destroying_user
    end
  end

  def update
    render_nothing(:unauthorized) and return unless current_user.id.to_s == params["id"]

    # Additional user settings.
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

    # User emails and passwords.
    if params["user_session"]
      user_session = params["user_session"]
      if current_user.reset_password_allowed
        password_is_valid = true
      elsif current_user.valid_password?(user_session["current_password"])
        password_is_valid = true
      else
        password_is_valid = false
      end

      unless password_is_valid
        @response = :error_validating_password
        respond_with(@response, template: "shared/user") and return
      end

      password_confirmed = user_session["password"] == user_session["password_confirmation"]
      unless password_confirmed
        @response = :error_confirmation_password
        respond_with(@response, template: "shared/user") and return
      end

      current_user.password = user_session["password"]
      current_user.password_confirmation = user_session["password_confirmation"]
      if current_user.changed? && current_user.save
        current_user.update_attribute(:reset_password_allowed, nil)
        @response = :password_successfully_changed
      else
        @response = :error_changing_password
      end
    end

    respond_with(@response, template: "shared/user")
  end
end

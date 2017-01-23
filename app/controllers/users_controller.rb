class UsersController < ApplicationController
  before_action :check_demo_mode, except: :edit

  def edit
    @user = current_user
  end

  respond_to :js

  def destroy
    user = User.find_by(id: params[:id])
    render_nothing(:bad_request) unless user
    flash[:notice] = if user.destroy
                       :user_destroyed
                     else
                       :error_destroying_user
                     end
  end

  def update
    unless current_user.id.to_s == params["id"]
      render_nothing(:unauthorized) and return
    end

    # Additional user settings.
    name = params["name"]
    corresponding_settings = Settings.values[name]
    if corresponding_settings
      value = params["value"]
      accepted_values = corresponding_settings[:accepted_values]
      if !accepted_values || accepted_values.include?(value)
        current_user.settings[name] = value
      end
      @response = if current_user.save
                    :user_settings_saved
                  else
                    :error_saving_user_settings
                  end
    end

    # User emails and passwords.
    if params["user_session"]
      user_session = params["user_session"]
      password_is_valid = current_user
                            .valid_password?(user_session["current_password"])
      password_is_accepted = if current_user.reset_password_allowed
                               true
                             elsif password_is_valid
                               true
                             else
                               false
                             end

      unless password_is_accepted
        @response = :error_validating_password
        respond_with(@response, template: "shared/user") and return
      end

      password_confirmed = user_session["password"] ==
                           user_session["password_confirmation"]
      unless password_confirmed
        @response = :error_confirmation_password
        respond_with(@response, template: "shared/user") and return
      end

      current_user.password = user_session["password"]
      current_user.password_confirmation = user_session["password_confirmation"]
      if current_user.changed? && current_user.save
        current_user.update_attributes(reset_password_allowed: nil)
        @response = :password_successfully_changed
      else
        @response = :error_changing_password
      end
    end

    respond_with(@response, template: "shared/user")
  end
end

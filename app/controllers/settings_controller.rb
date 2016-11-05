class SettingsController < ApplicationController
  def index
    if params[:general]
      saved_successfully = true
      params.each do |param, value|
        settings = Settings.find_by(var: param)
        if settings
          unless settings.update_attribute(:value, value)
            saved_successfully = false
            break
          end
        end
      end
      if saved_successfully
        flash[:notice] = :settings_saved
      else
        flash[:notice] = :error_saving_settings
      end
      redirect_to "/settings#general"

    elsif params[:users]
      user = User.find(params[:id])
      if user
        if user.update_attributes(role: params[:role], email: params[:email])
          flash[:notice] = :user_saved
        else
          flash[:notice] = :error_saving_user
        end
      end
      redirect_to "/settings#users"

    elsif params[:add_user]
      user = User.new(
        email: params[:email],
        password: params[:password],
        password_confirmation: params[:password],
        role: params[:role],
      )
      if user.save
        flash[:notice] = :user_created
        flash[:email] = params[:email]
        flash[:password] = params[:password]
      else
        flash[:notice] = :error_creating_user
      end
      redirect_to "/settings#users"
    end

    # "thing_id is null" means this settings are not users'
    @settings = Settings.unscoped.where("thing_id is null").reorder(var: :asc)
    @users = User.all.reorder(email: :asc)
  end
end

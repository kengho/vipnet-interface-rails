class SettingsController < ApplicationController
  before_action :check_demo_mode, except: :index
  before_action :check_administrator_role

  def index
    # "thing_id is null" means this settings is not users'.
    @settings = Settings
                  .unscoped
                  .where(
                    "var IN (?) AND thing_id is null",
                    Settings.values.keys,
                  )
    @users = User.all.reorder(email: :asc)
  end

  respond_to :js

  def update
    # TODO: check settings type.
    if params[:general]
      saved_successfully = true
      params.each do |param, value|
        settings = Settings.find_by(var: param)
        next unless settings

        unless settings.update_attributes(value: value)
          saved_successfully = false
          break
        end
      end
      flash[:notice] = if saved_successfully
                         :settings_saved
                       else
                         :error_saving_settings
                       end

    elsif params[:users]
      user = User.find(params[:id])
      return unless user

      user_updated = user.update_attributes(
        role: params[:role],
        email: params[:email],
      )
      flash[:notice] = if user_updated
                         :user_saved
                       else
                         :error_saving_user
                       end

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
    end
  end
end

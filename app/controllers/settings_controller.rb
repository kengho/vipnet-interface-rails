class SettingsController < ApplicationController

  def index
    # default settings
    unless Settings.support_email
      Settings.support_email = String.new
    end
    unless Settings.checker
      Settings.checker = "http://localhost:8080/?ip=#\{ip}&token=#\{token}"
    end
    unless Settings.nodes_per_page
      Settings.nodes_per_page = "10"
    end
    unless Settings.networks_to_ignore
      Settings.networks_to_ignore = "6670,6671"
    end

    if params[:general]
      params.each do |param, value|
        next if param == "general"
        settings = Settings.where("var = '#{param}'")
        if settings.size == 1
          setting = settings.first
          setting.value = value
          setting.save
        end
      end
      flash[:notice] = "settings saved"
      redirect_to "/settings#general"
    elsif params[:users]
      user = User.find(params[:id])
      user.role = params[:role]
      user.email = params[:email]
      if user.save
        flash[:notice] = "user saved"
        redirect_to "/settings#users"
      else
        render nothing: true, status: 500, content_type: "text/html"
      end
    elsif params[:add_user]
      user = User.new(  email: params[:email],
                        password: params[:password],
                        password_confirmation: params[:password],
                        role: params[:role] )
      if user.save
        flash[:notice] = "user created"
        flash[:password] = params[:password]
        flash[:email] = params[:email]
        redirect_to "/settings#users"
      else
        flash[:notice] = "error creating user"
        redirect_to "/settings#users"
      end
    end

    @settings = Settings.unscoped.where("thing_id is null").reorder("var ASC")
    @users = User.all.reorder("email ASC")
  end

end

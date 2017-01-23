module SettingsHelper
  def snackbarize(flash)
    return unless flash.notice

    default_timeout = 3000
    infinite_timeout = -1

    case flash.notice
    when :user_created
      message =
        "#{t('.snackbar.user_created')}\n"\
        "#{t('.snackbar.email')}: "\
        "#{flash[:email]}\n"\
        "#{t('.snackbar.password')}: "\
        "#{flash[:password]}"
      return message, infinite_timeout, :reload

    when :user_destroyed
      return t(".snackbar.user_destroyed"), default_timeout, :user_destroyed

    else
      message = case flash.notice
                when :user_created
                  t(".snackbar.user_created")
                when :error_creating_user
                  t(".snackbar.error_creating_user")
                when :user_saved
                  t(".snackbar.user_saved")
                when :error_saving_user
                  t(".snackbar.error_saving_user")
                when :settings_saved
                  t(".snackbar.settings_saved")
                when :error_saving_settings
                  t(".snackbar.error_saving_settings")
                end
      return message, default_timeout
    end
  end
end

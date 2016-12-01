module SettingsHelper
  def snackbarize(flash)
    if flash.notice
      default_timeout = 3000
      infinite_timeout = -1

      case flash[:notice]
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
        return t(".snackbar.#{flash.notice}"), default_timeout
      end
    end
  end
end

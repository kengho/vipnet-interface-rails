module SettingsHelper
  def snackbarize(flash)
    if flash.notice
      default_timeout = 3000
      infinite_timeout = -1
      if flash[:notice] == :user_created
        message =
          "#{t('.snackbar.user_created')}\n"\
          "#{t('.snackbar.email')}: "\
          "#{flash[:email]}\n"\
          "#{t('.snackbar.password')}: "\
          "#{flash[:password]}"
        return message, infinite_timeout, :reload
      else
        return t(".snackbar.#{flash.notice}"), default_timeout
      end
    end
  end
end

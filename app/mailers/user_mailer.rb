class UserMailer < ApplicationMailer
  def send_email(email)
    case email[:template]
    when :reset_password
      link = "#{Settings.host}/reset_password?token=#{email[:params][:token]}"
      mail(
        to: email[:to],
        subject: t("mailer.reset_password.subject"),
        body: t("mailer.reset_password.body", link: link),
      )
    end
  end
end

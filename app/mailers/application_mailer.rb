class ApplicationMailer < ActionMailer::Base
  default from: Settings.mailer_default_from
end

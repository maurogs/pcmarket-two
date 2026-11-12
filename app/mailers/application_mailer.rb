class ApplicationMailer < ActionMailer::Base
  helper MoneyHelper

  default from: "from@example.com"
  layout "mailer"
end

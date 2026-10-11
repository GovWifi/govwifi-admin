require "logger"
logger = Logger.new($stdout)

namespace :account_health do
  desc "Email organisation administrators about newly detected account health issues " \
       "(dry run unless ACCOUNT_HEALTH_EMAILS_ENABLED=true)"
  task send_notifications: :environment do
    logger.info("BEGIN: Sending account health notifications...")
    UseCases::AccountHealth::SendNotifications.new(logger:).execute
    logger.info("END: Sending account health notifications")
  end
end

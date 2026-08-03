require "logger"
logger = Logger.new($stdout)

namespace :metrics do
  desc "Publish orgs with no active admins count to S3 and post to metrics API"
  task publish_orgs_have_no_active_admins_count: :environment do
    logger.info("BEGIN: Publishing orgs with no active admins count...")
    UseCases::Administrator::PublishOrgsHaveNoActiveAdminsCount.new.publish
    logger.info("END: Publishing orgs with no active admins count")
  end
end

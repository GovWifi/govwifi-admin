require "logger"
logger = Logger.new($stdout)

namespace :metrics do
  desc "Publish orgs with dormant admins count to S3 and post to metrics API"
  task publish_orgs_with_dormant_admins_count: :environment do
    logger.info("BEGIN: Publishing orgs with dormant admins count...")
    UseCases::Administrator::PublishOrgsWithDormantAdminsCount.new.publish
    logger.info("END: Publishing orgs with dormant admins count")
  end
end

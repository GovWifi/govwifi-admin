require "logger"
logger = Logger.new($stdout)

namespace :metrics do
  desc "Publish orgs with less than two admins count to S3 and post to metrics API"
  task publish_orgs_with_less_than_two_admins_count: :environment do
    logger.info("BEGIN: Publishing orgs with less than two admins count...")
    UseCases::Administrator::PublishOrgsWithLessThanTwoAdminsCount.new.publish
    logger.info("END: Publishing orgs with less than two admins count")
  end
end

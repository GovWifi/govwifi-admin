require "logger"
logger = Logger.new($stdout)

namespace :metrics do
  desc "Publish orgs with no signed MOU count to S3 and post to metrics API"
  task publish_orgs_with_no_signed_mou_count: :environment do
    logger.info("BEGIN: Publishing orgs with no signed MOU count...")
    UseCases::Administrator::PublishOrgsWithNoSignedMouCount.new.publish
    logger.info("END: Publishing orgs with no signed MOU count")
  end
end

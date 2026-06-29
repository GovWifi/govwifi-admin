require "logger"
logger = Logger.new($stdout)

namespace :metrics do
  desc "Publish organisation count to S3 and post to metrics API"
  task publish_organisation_count: :environment do
    logger.info("BEGIN: Publishing organisation count...")
    UseCases::Administrator::PublishOrganisationCount.new.publish
    logger.info("END: Publishing organisation count")
  end
end

require "logger"

namespace :metrics do
  desc "Publish orgs with no physical address for IP count to S3 and post to metrics API"
  task publish_orgs_with_no_physical_address_for_ip_count: :environment do
    logger = Logger.new($stdout)
    logger.info("BEGIN: Publishing orgs with no physical address for IP count...")
    UseCases::Administrator::PublishOrgsWithNoPhysicalAddressForIpCount.new.publish
    logger.info("END: Publishing orgs with no physical address for IP count")
  end
end

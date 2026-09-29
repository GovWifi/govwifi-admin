require "logger"

namespace :metrics do
  desc "Publish organisations added (month-to-date and 30 day rolling window) to S3 and post to metrics API"
  task :publish_organisations_added, [:date] => :environment do |_, args|
    args.with_defaults(date: Time.zone.today.to_s)
    logger = Logger.new($stdout)

    logger.info("Creating organisations added metrics for S3 with #{args[:date]}")

    UseCases::Administrator::PublishOrganisationsAdded.new(
      date: args[:date],
      logger:,
    ).publish
  end
end

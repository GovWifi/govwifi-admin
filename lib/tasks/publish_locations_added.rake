# frozen_string_literal: true

require "logger"

namespace :metrics do
  desc "Publishes monthly rolling window and month-to-date counts of locations added to S3 and the Metrics API"
  task :publish_locations_added, [:date] => :environment do |_, args|
    logger = Logger.new($stdout)
    date = if args[:date].present?
             Date.parse(args[:date])
           else
             Time.zone.today
           end

    logger.info("Starting publish_locations_added for date: #{date}")
    UseCases::Administrator::PublishLocationsAdded.execute(date:, logger:)
    logger.info("Completed publish_locations_added for date: #{date}")
  end
end

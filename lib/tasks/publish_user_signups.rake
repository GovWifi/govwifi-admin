# frozen_string_literal: true

require "logger"

namespace :metrics do
  desc "Publish user signups (End User, Email, and SMS month-to-date and 30 day rolling window) to S3 and post to metrics API"
  task :publish_user_signups, [:date] => :environment do |_, args|
    args.with_defaults(date: Time.zone.today.to_s)
    logger = Logger.new($stdout)

    logger.info("Creating user signups metrics for S3 with #{args[:date]}")

    UseCases::Administrator::PublishUserSignups.new(
      date: args[:date],
      logger:,
    ).publish
  end
end

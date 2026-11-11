# frozen_string_literal: true

require "logger"

namespace :metrics do
  desc "Import historical reporting figures from an ODS spreadsheet into the Metrics API without overwriting existing records"
  task :import_historical_data, %i[file_path dry_run] => :environment do |_, args|
    default_path = ENV.fetch(
      "HISTORICAL_METRICS_ODS_PATH",
      Gateways::HistoricalReportingSpreadsheet::DEFAULT_FILE_PATH,
    )
    args.with_defaults(file_path: default_path, dry_run: "false")

    logger = Logger.new($stdout)
    dry_run = %w[true 1 yes].include?(args[:dry_run].to_s.strip.downcase)

    logger.info("Importing historical metrics from #{args[:file_path]} (dry_run: #{dry_run})")

    summary = UseCases::Administrator::ImportHistoricalMetrics.new(
      file_path: args[:file_path],
      dry_run:,
      logger:,
    ).execute

    raise "Historical metrics import failed for #{summary[:failed]} record(s)" if summary[:failed].positive?
  end
end

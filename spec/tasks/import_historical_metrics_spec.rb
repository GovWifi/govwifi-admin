# frozen_string_literal: true

require "rails_helper"
require "rake"

describe "metrics:import_historical_data rake task" do
  before do
    Rake::Task.define_task(:environment) unless Rake::Task.task_defined?(:environment)
    Rake::Task["metrics:import_historical_data"]&.clear if Rake::Task.task_defined?("metrics:import_historical_data")
    load File.expand_path("../../lib/tasks/import_historical_metrics.rake", __dir__)
  end

  it "delegates to UseCases::Administrator::ImportHistoricalMetrics with custom file_path and dry_run arguments" do
    use_case_double = instance_double(
      UseCases::Administrator::ImportHistoricalMetrics,
      execute: { total: 18, recorded: 18, skipped: 0, failed: 0 },
    )

    expect(UseCases::Administrator::ImportHistoricalMetrics).to receive(:new).with(
      file_path: "/tmp/custom_figures.ods",
      dry_run: true,
      logger: anything,
    ).and_return(use_case_double)

    Rake::Task["metrics:import_historical_data"].reenable
    Rake::Task["metrics:import_historical_data"].invoke("/tmp/custom_figures.ods", "true")
  end

  it "uses the default spreadsheet path and dry_run=false when no arguments are supplied" do
    use_case_double = instance_double(
      UseCases::Administrator::ImportHistoricalMetrics,
      execute: { total: 18, recorded: 10, skipped: 8, failed: 0 },
    )

    expect(UseCases::Administrator::ImportHistoricalMetrics).to receive(:new).with(
      file_path: Gateways::HistoricalReportingSpreadsheet::DEFAULT_FILE_PATH,
      dry_run: false,
      logger: anything,
    ).and_return(use_case_double)

    Rake::Task["metrics:import_historical_data"].reenable
    Rake::Task["metrics:import_historical_data"].invoke
  end

  it "raises RuntimeError when one or more metric uploads fail" do
    use_case_double = instance_double(
      UseCases::Administrator::ImportHistoricalMetrics,
      execute: { total: 18, recorded: 16, skipped: 0, failed: 2 },
    )

    allow(UseCases::Administrator::ImportHistoricalMetrics).to receive(:new).and_return(use_case_double)

    Rake::Task["metrics:import_historical_data"].reenable
    expect {
      Rake::Task["metrics:import_historical_data"].invoke("/tmp/custom_figures.ods")
    }.to raise_error(RuntimeError, /Historical metrics import failed for 2 record\(s\)/)
  end
end

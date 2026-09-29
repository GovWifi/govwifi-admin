# frozen_string_literal: true

require "rails_helper"

describe Performance::Metrics::OrganisationsAddedMetricSender do
  let(:today) { Date.parse("2026-07-17") }
  let(:logger) { instance_double(Logger, info: nil, warn: nil) }
  let(:s3_bucket) { "test-metrics-bucket" }

  around do |example|
    original_bucket = ENV["S3_METRICS_BUCKET"]
    ENV["S3_METRICS_BUCKET"] = s3_bucket
    example.run
    ENV["S3_METRICS_BUCKET"] = original_bucket
  end

  describe "initialization" do
    it "accepts valid metric keys" do
      expect {
        described_class.new(metric: :monthly_rolling_organisations_added, date: today, logger:)
      }.not_to raise_error

      expect {
        described_class.new(metric: :month_to_date_organisations_added, date: today, logger:)
      }.not_to raise_error
    end

    it "raises ArgumentError on unknown metric keys" do
      expect {
        described_class.new(metric: :invalid_metric, date: today, logger:)
      }.to raise_error(ArgumentError)
    end
  end

  describe "naming and paths" do
    it "provides correct folder and filename for monthly rolling organisations added" do
      sender = described_class.new(metric: :monthly_rolling_organisations_added, date: today, logger:)
      expect(sender.folder).to eq("service-report-organisations-addeded-rolling-count")
      expect(sender.filename).to eq("service-report-organisations-addeded-rolling-count-2026-07-17")
      expect(sender.key).to eq("service-report-organisations-addeded-rolling-count-2026-07-17")
    end

    it "provides correct folder and filename for month to date organisations added" do
      sender = described_class.new(metric: :month_to_date_organisations_added, date: today, logger:)
      expect(sender.folder).to eq("service-report-organisations-addeded-mtd-count")
      expect(sender.filename).to eq("service-report-organisations-addeded-mtd-count-2026-07-17")
      expect(sender.key).to eq("service-report-organisations-addeded-mtd-count-2026-07-17")
    end
  end

  describe "#to_s3" do
    let(:s3_gateway) { instance_double(Gateways::S3) }

    context "with monthly rolling organisations added metric" do
      subject(:sender) { described_class.new(metric: :monthly_rolling_organisations_added, date: today, logger:) }

      let(:use_case) { instance_double(Performance::UseCase::MonthlyRollingWindowOrganisationsAdded) }

      before do
        allow(Performance::UseCase::MonthlyRollingWindowOrganisationsAdded).to receive(:new).with(
          period: "day",
          date: today,
        ).and_return(use_case)

        allow(use_case).to receive(:fetch_stats).and_return(
          count: 47_073,
          run_time: "2026-07-17",
          metric_name: "service-report-organisations-addeded-rolling-count",
          period: "day",
          date: "2026-07-17",
        )
      end

      it "writes the single-line JSON payload to S3" do
        expected_key = "service-report-organisations-addeded-rolling-count/service-report-organisations-addeded-rolling-count-2026-07-17"
        expected_json = "{\"count\":47073,\"metric_name\":\"service-report-organisations-addeded-rolling-count\",\"period\":\"day\",\"date\":\"2026-07-17\"}\n"

        expect(Gateways::S3).to receive(:new).with(
          bucket: s3_bucket,
          key: expected_key,
        ).and_return(s3_gateway)

        expect(s3_gateway).to receive(:write).with(expected_json)

        sender.to_s3
      end
    end

    context "with month to date organisations added metric" do
      subject(:sender) { described_class.new(metric: :month_to_date_organisations_added, date: today, logger:) }

      let(:use_case) { instance_double(Performance::UseCase::MonthToDateOrganisationsAdded) }

      before do
        allow(Performance::UseCase::MonthToDateOrganisationsAdded).to receive(:new).with(
          period: "day",
          date: today,
        ).and_return(use_case)

        allow(use_case).to receive(:fetch_stats).and_return(
          count: 12_500,
          run_time: "2026-07-17",
          metric_name: "service-report-organisations-addeded-mtd-count",
          period: "day",
          date: "2026-07-17",
        )
      end

      it "writes the single-line JSON payload to S3" do
        expected_key = "service-report-organisations-addeded-mtd-count/service-report-organisations-addeded-mtd-count-2026-07-17"
        expected_json = "{\"count\":12500,\"metric_name\":\"service-report-organisations-addeded-mtd-count\",\"period\":\"day\",\"date\":\"2026-07-17\"}\n"

        expect(Gateways::S3).to receive(:new).with(
          bucket: s3_bucket,
          key: expected_key,
        ).and_return(s3_gateway)

        expect(s3_gateway).to receive(:write).with(expected_json)

        sender.to_s3
      end
    end
  end

  describe "#to_api" do
    subject(:sender) { described_class.new(metric: :month_to_date_organisations_added, date: today, logger:) }

    let(:use_case) { instance_double(Performance::UseCase::MonthToDateOrganisationsAdded) }
    let(:stats) do
      {
        count: 12_500,
        run_time: "2026-07-17",
        metric_name: "service-report-organisations-addeded-mtd-count",
        period: "day",
        date: "2026-07-17",
      }
    end

    before do
      allow(Performance::UseCase::MonthToDateOrganisationsAdded).to receive(:new).and_return(use_case)
      allow(use_case).to receive(:fetch_stats).and_return(stats)
    end

    it "publishes stats via MetricsApiPublisher" do
      response = instance_double(Faraday::Response, success?: true, status: 200)
      expect(UseCases::PerformancePlatform::MetricsApiPublisher).to receive(:publish).with(stats).and_return(response)
      expect(logger).to receive(:info).with(/Metrics API upload succeeded/)

      sender.to_api
    end

    it "logs a warning when MetricsApiPublisher returns a failure status" do
      response = instance_double(Faraday::Response, success?: false, status: 500, body: "Server Error")
      allow(UseCases::PerformancePlatform::MetricsApiPublisher).to receive(:publish).with(stats).and_return(response)
      expect(logger).to receive(:warn).with(/Metrics API upload failed \(status: 500\): Server Error/)

      sender.to_api
    end

    it "logs a warning when MetricsApiPublisher returns nil (connection error)" do
      allow(UseCases::PerformancePlatform::MetricsApiPublisher).to receive(:publish).with(stats).and_return(nil)
      expect(logger).to receive(:warn).with(/Metrics API upload failed: connection or other error/)

      sender.to_api
    end
  end
end

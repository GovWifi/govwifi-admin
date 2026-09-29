# frozen_string_literal: true

describe Performance::Metrics::LocationsAddedMetricSender do
  let(:date) { Date.new(2026, 7, 17) }
  let(:s3_gateway) { instance_double(Gateways::S3) }
  let(:s3_bucket) { "test-metrics-bucket" }
  let(:logger) { instance_double(Logger, info: nil, warn: nil) }

  before do
    allow(ENV).to receive(:fetch).with("S3_METRICS_BUCKET").and_return(s3_bucket)
    allow(Gateways::S3).to receive(:new).and_return(s3_gateway)
  end

  describe "#initialize" do
    it "raises ArgumentError when metric is not recognized" do
      expect {
        described_class.new(metric: :unknown_metric, date:, logger:)
      }.to raise_error(ArgumentError)
    end

    it "initializes successfully for monthly_rolling_locations_added" do
      sender = described_class.new(metric: :monthly_rolling_locations_added, date:, logger:)
      expect(sender.folder).to eq("service-report-locations-added-rolling-count")
      expect(sender.filename).to eq("service-report-locations-added-rolling-count-2026-07-17")
    end

    it "initializes successfully for month_to_date_locations_added" do
      sender = described_class.new(metric: :month_to_date_locations_added, date:, logger:)
      expect(sender.folder).to eq("service-report-locations-added-mtd-count")
      expect(sender.filename).to eq("service-report-locations-added-mtd-count-2026-07-17")
    end
  end

  describe "#to_s3" do
    context "with monthly_rolling_locations_added" do
      subject(:sender) { described_class.new(metric: :monthly_rolling_locations_added, date:, logger:) }

      let(:use_case) { instance_double(Performance::UseCase::MonthlyRollingWindowLocationsAdded) }
      let(:stats) do
        {
          count: 47_073,
          metric_name: "service-report-locations-added-rolling-count",
          period: "day",
          date: "2026-07-17",
        }
      end

      before do
        allow(Performance::UseCase::MonthlyRollingWindowLocationsAdded).to receive(:new)
          .with(period: "day", date:)
          .and_return(use_case)
        allow(use_case).to receive(:fetch_stats).and_return(stats)
      end

      it "writes single-line JSON to S3 with correct path" do
        expected_json = "#{stats.to_json}\n"
        expect(Gateways::S3).to receive(:new).with(
          bucket: s3_bucket,
          key: "service-report-locations-added-rolling-count/service-report-locations-added-rolling-count-2026-07-17",
        ).and_return(s3_gateway)
        expect(s3_gateway).to receive(:write).with(expected_json)

        sender.to_s3
      end
    end

    context "with month_to_date_locations_added" do
      subject(:sender) { described_class.new(metric: :month_to_date_locations_added, date:, logger:) }

      let(:use_case) { instance_double(Performance::UseCase::MonthToDateLocationsAdded) }
      let(:stats) do
        {
          count: 12_500,
          metric_name: "service-report-locations-added-mtd-count",
          period: "day",
          date: "2026-07-17",
        }
      end

      before do
        allow(Performance::UseCase::MonthToDateLocationsAdded).to receive(:new)
          .with(period: "day", date:)
          .and_return(use_case)
        allow(use_case).to receive(:fetch_stats).and_return(stats)
      end

      it "writes single-line JSON to S3 with correct path" do
        expected_json = "#{stats.to_json}\n"
        expect(Gateways::S3).to receive(:new).with(
          bucket: s3_bucket,
          key: "service-report-locations-added-mtd-count/service-report-locations-added-mtd-count-2026-07-17",
        ).and_return(s3_gateway)
        expect(s3_gateway).to receive(:write).with(expected_json)

        sender.to_s3
      end
    end

    context "when stats is nil" do
      subject(:sender) { described_class.new(metric: :month_to_date_locations_added, date:, logger:) }

      let(:use_case) { instance_double(Performance::UseCase::MonthToDateLocationsAdded) }

      before do
        allow(Performance::UseCase::MonthToDateLocationsAdded).to receive(:new)
          .with(period: "day", date:)
          .and_return(use_case)
        allow(use_case).to receive(:fetch_stats).and_return(nil)
      end

      it "does not write to S3" do
        expect(Gateways::S3).not_to receive(:new)
        sender.to_s3
      end
    end
  end

  describe "#to_api" do
    subject(:sender) { described_class.new(metric: :month_to_date_locations_added, date:, logger:) }

    let(:use_case) { instance_double(Performance::UseCase::MonthToDateLocationsAdded) }
    let(:stats) do
      {
        count: 12_500,
        metric_name: "service-report-locations-added-mtd-count",
        period: "day",
        date: "2026-07-17",
      }
    end

    before do
      allow(Performance::UseCase::MonthToDateLocationsAdded).to receive(:new)
        .with(period: "day", date:)
        .and_return(use_case)
      allow(use_case).to receive(:fetch_stats).and_return(stats)
    end

    it "calls MetricsApiPublisher.publish with stats and logs success" do
      response = instance_double(Faraday::Response, success?: true, status: 200)
      expect(UseCases::PerformancePlatform::MetricsApiPublisher).to receive(:publish).with(stats).and_return(response)
      expect(logger).to receive(:info).with(/Metrics API upload succeeded/)

      sender.to_api
    end

    it "logs warning when MetricsApiPublisher returns unsuccessful response" do
      response = instance_double(Faraday::Response, success?: false, status: 500, body: "Server Error")
      expect(UseCases::PerformancePlatform::MetricsApiPublisher).to receive(:publish).with(stats).and_return(response)
      expect(logger).to receive(:warn).with(/Metrics API upload failed.*500/)

      sender.to_api
    end

    it "logs warning when MetricsApiPublisher returns nil" do
      expect(UseCases::PerformancePlatform::MetricsApiPublisher).to receive(:publish).with(stats).and_return(nil)
      expect(logger).to receive(:warn).with(/Metrics API upload failed: connection or other error/)

      sender.to_api
    end

    context "when stats is nil" do
      before do
        allow(use_case).to receive(:fetch_stats).and_return(nil)
      end

      it "logs info and does not contact Metrics API" do
        expect(UseCases::PerformancePlatform::MetricsApiPublisher).not_to receive(:publish)
        expect(logger).to receive(:info).with(/No stats to upload/)

        sender.to_api
      end
    end
  end
end

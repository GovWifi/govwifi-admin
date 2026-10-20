# frozen_string_literal: true

require "rails_helper"

describe Performance::Metrics::UserSignupsMetricSender do
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
    it "accepts all six valid user signup metric keys" do
      described_class::STATS.each_key do |metric|
        expect {
          described_class.new(metric:, date: today, logger:)
        }.not_to raise_error
      end
    end

    it "raises ArgumentError on unknown metric keys" do
      expect {
        described_class.new(metric: :invalid_metric, date: today, logger:)
      }.to raise_error(ArgumentError)
    end
  end

  describe "naming and paths" do
    {
      monthly_rolling_end_user_signups: "service-report-end-user-signups-rolling-count",
      month_to_date_end_user_signups: "service-report-end-user-signups-mtd-count",
      monthly_rolling_email_signups: "service-report-email-signups-rolling-count",
      month_to_date_email_signups: "service-report-email-signups-mtd-count",
      monthly_rolling_sms_signups: "service-report-sms-signups-rolling-count",
      month_to_date_sms_signups: "service-report-sms-signups-mtd-count",
    }.each do |metric_key, expected_folder|
      it "provides correct folder, filename, and key for #{metric_key}" do
        sender = described_class.new(metric: metric_key, date: today, logger:)
        expect(sender.folder).to eq(expected_folder)
        expect(sender.filename).to eq("#{expected_folder}-2026-07-17")
        expect(sender.key).to eq("#{expected_folder}-2026-07-17")
      end
    end
  end

  describe "#to_s3" do
    let(:s3_gateway) { instance_double(Gateways::S3) }

    {
      monthly_rolling_end_user_signups: [
        Performance::UseCase::MonthlyRollingWindowEndUserSignups,
        "service-report-end-user-signups-rolling-count",
        47_073,
      ],
      month_to_date_end_user_signups: [
        Performance::UseCase::MonthToDateEndUserSignups,
        "service-report-end-user-signups-mtd-count",
        12_500,
      ],
      monthly_rolling_email_signups: [
        Performance::UseCase::MonthlyRollingWindowEmailSignups,
        "service-report-email-signups-rolling-count",
        30_000,
      ],
      month_to_date_email_signups: [
        Performance::UseCase::MonthToDateEmailSignups,
        "service-report-email-signups-mtd-count",
        8_200,
      ],
      monthly_rolling_sms_signups: [
        Performance::UseCase::MonthlyRollingWindowSmsSignups,
        "service-report-sms-signups-rolling-count",
        17_073,
      ],
      month_to_date_sms_signups: [
        Performance::UseCase::MonthToDateSmsSignups,
        "service-report-sms-signups-mtd-count",
        4_300,
      ],
    }.each do |metric_key, (use_case_class, metric_name, sample_count)|
      context "with #{metric_key} metric" do
        subject(:sender) { described_class.new(metric: metric_key, date: today, logger:) }

        let(:use_case) { instance_double(use_case_class) }

        before do
          allow(use_case_class).to receive(:new).with(
            period: "day",
            date: today,
          ).and_return(use_case)

          allow(use_case).to receive(:fetch_stats).and_return(
            count: sample_count,
            run_time: "2026-07-17",
            metric_name:,
            period: "day",
            date: "2026-07-17",
          )
        end

        it "writes the single-line JSON payload to S3" do
          expected_key = "#{metric_name}/#{metric_name}-2026-07-17"
          expected_json = "{\"count\":#{sample_count},\"metric_name\":\"#{metric_name}\",\"period\":\"day\",\"date\":\"2026-07-17\"}\n"

          expect(Gateways::S3).to receive(:new).with(
            bucket: s3_bucket,
            key: expected_key,
          ).and_return(s3_gateway)

          expect(s3_gateway).to receive(:write).with(expected_json)

          sender.to_s3
        end
      end
    end

    context "when stats is nil" do
      subject(:sender) { described_class.new(metric: :month_to_date_end_user_signups, date: today, logger:) }

      let(:use_case) { instance_double(Performance::UseCase::MonthToDateEndUserSignups, fetch_stats: nil) }

      before do
        allow(Performance::UseCase::MonthToDateEndUserSignups).to receive(:new).and_return(use_case)
      end

      it "does not write to S3" do
        expect(Gateways::S3).not_to receive(:new)
        sender.to_s3
      end
    end
  end

  describe "#to_api" do
    subject(:sender) { described_class.new(metric: :month_to_date_end_user_signups, date: today, logger:) }

    let(:use_case) { instance_double(Performance::UseCase::MonthToDateEndUserSignups) }
    let(:stats) do
      {
        count: 12_500,
        run_time: "2026-07-17",
        metric_name: "service-report-end-user-signups-mtd-count",
        period: "day",
        date: "2026-07-17",
      }
    end

    before do
      allow(Performance::UseCase::MonthToDateEndUserSignups).to receive(:new).and_return(use_case)
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

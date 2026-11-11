# frozen_string_literal: true

require "rails_helper"

describe UseCases::Administrator::ImportHistoricalMetrics do
  subject(:use_case) do
    described_class.new(
      spreadsheet_gateway:,
      publisher:,
      logger:,
      dry_run:,
    )
  end

  let(:spreadsheet_gateway) { instance_double(Gateways::HistoricalReportingSpreadsheet, entries: sample_entries) }
  let(:publisher) { class_double(UseCases::PerformancePlatform::MetricsApiPublisher) }
  let(:logger) { instance_spy(Logger) }
  let(:dry_run) { false }

  let(:sample_entries) do
    [
      {
        sheet: "Archive",
        month: "January 2023",
        column: "Active Users",
        metric_name: "monthly-rolling-window-total-active-users",
        value: "444000",
        datetime: "2023-01-01T00:00:00Z",
      },
      {
        sheet: "Archive",
        month: "January 2023",
        column: "Active Users",
        metric_name: "month-to-date-total-active-users",
        value: "444000",
        datetime: "2023-01-01T00:00:00Z",
      },
      {
        sheet: "Monthly Analytics Reporting",
        month: "September 2026",
        column: "Locations Added",
        metric_name: "service-report-locations-added-rolling-count",
        value: "20",
        datetime: "2026-09-01T00:00:00Z",
      },
    ]
  end

  describe "#execute" do
    context "when all metrics are newly recorded (201 Created)" do
      let(:created_response) { instance_double(Faraday::Response, success?: true, status: 201, body: '{"message":"Metric recorded successfully"}') }

      before do
        allow(publisher).to receive(:publish).and_return(created_response)
      end

      it "publishes every entry to the Metrics API and returns the recorded summary" do
        summary = use_case.execute

        expect(summary).to eq(
          total: 3,
          recorded: 3,
          skipped: 0,
          failed: 0,
        )
        expect(publisher).to have_received(:publish).with(
          metric_name: "monthly-rolling-window-total-active-users",
          value: "444000",
          datetime: "2023-01-01T00:00:00Z",
        )
        expect(publisher).to have_received(:publish).with(
          metric_name: "month-to-date-total-active-users",
          value: "444000",
          datetime: "2023-01-01T00:00:00Z",
        )
        expect(publisher).to have_received(:publish).with(
          metric_name: "service-report-locations-added-rolling-count",
          value: "20",
          datetime: "2026-09-01T00:00:00Z",
        )
        expect(logger).to have_received(:info).with(/Historical metrics import complete: total=3, recorded=3, skipped=0, failed=0/)
      end
    end

    context "when re-running import and some metrics already exist in the Metrics API" do
      let(:duplicate_response) do
        instance_double(
          Faraday::Response,
          success?: false,
          status: 422,
          body: '{"error":"Metric \'monthly-rolling-window-total-active-users\' at \'2023-01-01 00:00:00 UTC\' already exists"}',
        )
      end
      let(:conflict_response) do
        instance_double(
          Faraday::Response,
          success?: false,
          status: 409,
          body: '{"error":"Conflict"}',
        )
      end
      let(:created_response) do
        instance_double(
          Faraday::Response,
          success?: true,
          status: 201,
          body: '{"message":"Metric recorded successfully"}',
        )
      end

      before do
        allow(publisher).to receive(:publish).with(
          metric_name: "monthly-rolling-window-total-active-users",
          value: "444000",
          datetime: "2023-01-01T00:00:00Z",
        ).and_return(duplicate_response)

        allow(publisher).to receive(:publish).with(
          metric_name: "month-to-date-total-active-users",
          value: "444000",
          datetime: "2023-01-01T00:00:00Z",
        ).and_return(conflict_response)

        allow(publisher).to receive(:publish).with(
          metric_name: "service-report-locations-added-rolling-count",
          value: "20",
          datetime: "2026-09-01T00:00:00Z",
        ).and_return(created_response)
      end

      it "skips existing metrics without overwriting them and records only the missing metrics" do
        summary = use_case.execute

        expect(summary).to eq(
          total: 3,
          recorded: 1,
          skipped: 2,
          failed: 0,
        )
        expect(logger).to have_received(:info).with(/Skipped existing metric record \(not overwritten\)/).twice
        expect(logger).to have_received(:info).with(/Metrics API upload succeeded \(status: 201, value: 20\)/)
      end
    end

    context "when dry_run is enabled" do
      let(:dry_run) { true }

      before do
        allow(publisher).to receive(:publish)
      end

      it "logs the planned records without calling the Metrics API publisher" do
        summary = use_case.execute

        expect(summary).to eq(
          total: 3,
          recorded: 3,
          skipped: 0,
          failed: 0,
        )
        expect(publisher).not_to have_received(:publish)
        expect(logger).to have_received(:info).with(/\[DRY RUN\] \[monthly-rolling-window-total-active-users @ 2023-01-01T00:00:00Z\] Would record value=444000/)
      end
    end

    context "when the Metrics API returns an error status or connection failure" do
      let(:server_error_response) do
        instance_double(
          Faraday::Response,
          success?: false,
          status: 500,
          body: '{"error":"Internal server error"}',
        )
      end
      let(:validation_error_response) do
        instance_double(
          Faraday::Response,
          success?: false,
          status: 422,
          body: '{"error":"value must be a float, an integer, a decimal, or a decimal string"}',
        )
      end

      before do
        allow(publisher).to receive(:publish).with(
          metric_name: "monthly-rolling-window-total-active-users",
          value: "444000",
          datetime: "2023-01-01T00:00:00Z",
        ).and_return(server_error_response)

        allow(publisher).to receive(:publish).with(
          metric_name: "month-to-date-total-active-users",
          value: "444000",
          datetime: "2023-01-01T00:00:00Z",
        ).and_return(validation_error_response)

        allow(publisher).to receive(:publish).with(
          metric_name: "service-report-locations-added-rolling-count",
          value: "20",
          datetime: "2026-09-01T00:00:00Z",
        ).and_return(nil)
      end

      it "logs warnings and counts failed uploads" do
        summary = use_case.execute

        expect(summary).to eq(
          total: 3,
          recorded: 0,
          skipped: 0,
          failed: 3,
        )
        expect(logger).to have_received(:warn).with(/Metrics API upload failed \(status: 500\)/)
        expect(logger).to have_received(:warn).with(/Metrics API upload failed \(status: 422\)/)
        expect(logger).to have_received(:warn).with(/Metrics API upload failed: connection or other error/)
      end
    end
  end

  describe ".execute" do
    it "instantiates the use case and executes the import" do
      created_response = instance_double(Faraday::Response, success?: true, status: 201)
      allow(publisher).to receive(:publish).and_return(created_response)

      summary = described_class.execute(
        spreadsheet_gateway:,
        publisher:,
        logger:,
      )

      expect(summary[:recorded]).to eq(3)
    end
  end
end

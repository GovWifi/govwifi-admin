# frozen_string_literal: true

describe UseCases::Administrator::PublishLocationsAdded do
  let(:date) { Date.new(2026, 7, 17) }
  let(:logger) { instance_double(Logger, info: nil) }
  let(:rolling_sender) { instance_double(Performance::Metrics::LocationsAddedMetricSender, key: "rolling-key", to_s3: nil, to_api: nil) }
  let(:mtd_sender) { instance_double(Performance::Metrics::LocationsAddedMetricSender, key: "mtd-key", to_s3: nil, to_api: nil) }

  before do
    allow(Performance::Metrics::LocationsAddedMetricSender).to receive(:new)
      .with(metric: :monthly_rolling_locations_added, date:, logger:)
      .and_return(rolling_sender)
    allow(Performance::Metrics::LocationsAddedMetricSender).to receive(:new)
      .with(metric: :month_to_date_locations_added, date:, logger:)
      .and_return(mtd_sender)
  end

  describe ".execute" do
    it "instantiates and calls execute" do
      expect(rolling_sender).to receive(:to_s3)
      expect(rolling_sender).to receive(:to_api)
      expect(mtd_sender).to receive(:to_s3)
      expect(mtd_sender).to receive(:to_api)

      described_class.execute(date:, logger:)
    end

    it "logs progress for each metric" do
      expect(logger).to receive(:info).with("BEGIN: [rolling-key] Fetching and uploading locations added metrics...")
      expect(logger).to receive(:info).with("END: [rolling-key] Done.")
      expect(logger).to receive(:info).with("BEGIN: [mtd-key] Fetching and uploading locations added metrics...")
      expect(logger).to receive(:info).with("END: [mtd-key] Done.")

      described_class.execute(date:, logger:)
    end
  end
end

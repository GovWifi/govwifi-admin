# frozen_string_literal: true

describe Performance::UseCase::MonthToDateLocationsAdded do
  subject(:use_case) { described_class.new(date:, period: "day") }

  let(:date) { Date.new(2026, 7, 17) }
  let(:repository) { Performance::Repository::Location }

  before do
    allow(repository).to receive(:month_to_date_locations_added)
      .with(date:)
      .and_return({ total: 125, run_time: "2026-07-17" })
  end

  it "returns the month-to-date stats for locations added" do
    expect(use_case.fetch_stats).to eq({
      count: 125,
      run_time: "2026-07-17",
      metric_name: "service-report-locations-added-mtd-count",
      period: "day",
      date: "2026-07-17",
    })
  end

  context "when the repository returns nil" do
    before do
      allow(repository).to receive(:month_to_date_locations_added)
        .with(date:)
        .and_return(nil)
    end

    it "defaults count to 0 and run_time to date" do
      expect(use_case.fetch_stats).to eq({
        count: 0,
        run_time: "2026-07-17",
        metric_name: "service-report-locations-added-mtd-count",
        period: "day",
        date: "2026-07-17",
      })
    end
  end

  context "when total is nil in result" do
    before do
      allow(repository).to receive(:month_to_date_locations_added)
        .with(date:)
        .and_return({ total: nil, run_time: "2026-07-17" })
    end

    it "defaults count to 0" do
      expect(use_case.fetch_stats[:count]).to eq(0)
    end
  end
end

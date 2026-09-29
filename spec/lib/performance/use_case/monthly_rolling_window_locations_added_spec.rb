# frozen_string_literal: true

describe Performance::UseCase::MonthlyRollingWindowLocationsAdded do
  subject(:use_case) { described_class.new(date:, period: "day") }

  let(:date) { Date.new(2026, 7, 17) }
  let(:repository) { Performance::Repository::Location }

  before do
    allow(repository).to receive(:monthly_rolling_window_locations_added)
      .with(date:)
      .and_return({ total: 350, run_time: "2026-07-17" })
  end

  it "returns the 30-day rolling window stats for locations added" do
    expect(use_case.fetch_stats).to eq({
      count: 350,
      run_time: "2026-07-17",
      metric_name: "service-report-locations-added-rolling-count",
      period: "day",
      date: "2026-07-17",
    })
  end

  context "when the repository returns nil" do
    before do
      allow(repository).to receive(:monthly_rolling_window_locations_added)
        .with(date:)
        .and_return(nil)
    end

    it "defaults count to 0 and run_time to date" do
      expect(use_case.fetch_stats).to eq({
        count: 0,
        run_time: "2026-07-17",
        metric_name: "service-report-locations-added-rolling-count",
        period: "day",
        date: "2026-07-17",
      })
    end
  end

  context "when total is nil in result" do
    before do
      allow(repository).to receive(:monthly_rolling_window_locations_added)
        .with(date:)
        .and_return({ total: nil, run_time: "2026-07-17" })
    end

    it "defaults count to 0" do
      expect(use_case.fetch_stats[:count]).to eq(0)
    end
  end
end

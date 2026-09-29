# frozen_string_literal: true

require "rails_helper"

describe Performance::UseCase::MonthToDateOrganisationsAdded do
  let(:today) { Date.parse("2026-07-17") }
  let(:repository) { class_double(Performance::Repository::Organisation) }

  subject(:use_case) { described_class.new(period: "day", date: today) }

  before do
    allow(use_case).to receive(:repository).and_return(repository)
  end

  context "when organisations were added this month" do
    before do
      allow(repository).to receive(:month_to_date_organisations_added).with(date: today).and_return(
        run_time: "2026-07-17",
        total: 42,
      )
    end

    it "returns the expected stats payload" do
      expect(use_case.fetch_stats).to eq(
        count: 42,
        run_time: "2026-07-17",
        metric_name: "service-report-organisations-addeded-mtd-count",
        period: "day",
        date: "2026-07-17",
      )
    end
  end

  context "when no organisations were added this month" do
    before do
      allow(repository).to receive(:month_to_date_organisations_added).with(date: today).and_return(
        run_time: "2026-07-17",
        total: 0,
      )
    end

    it "returns zero count" do
      expect(use_case.fetch_stats).to eq(
        count: 0,
        run_time: "2026-07-17",
        metric_name: "service-report-organisations-addeded-mtd-count",
        period: "day",
        date: "2026-07-17",
      )
    end
  end

  context "when repository returns nil" do
    before do
      allow(repository).to receive(:month_to_date_organisations_added).with(date: today).and_return(nil)
    end

    it "handles nil gracefully and defaults to 0 and date string" do
      expect(use_case.fetch_stats).to eq(
        count: 0,
        run_time: "2026-07-17",
        metric_name: "service-report-organisations-addeded-mtd-count",
        period: "day",
        date: "2026-07-17",
      )
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

describe Performance::UseCase::MonthToDateEndUserSignups do
  let(:today) { Date.parse("2026-07-17") }
  let(:repository) { class_double(Performance::Repository::UserSignups) }

  subject(:use_case) { described_class.new(period: "day", date: today) }

  before do
    allow(use_case).to receive(:repository).and_return(repository)
  end

  context "when end user signups occurred this month" do
    before do
      allow(repository).to receive(:month_to_date_end_user_signups).with(date: today).and_return(
        run_time: "2026-07-17",
        total: 12_500,
      )
    end

    it "returns the expected stats payload" do
      expect(use_case.fetch_stats).to eq(
        count: 12_500,
        run_time: "2026-07-17",
        metric_name: "service-report-end-user-signups-mtd-count",
        period: "day",
        date: "2026-07-17",
      )
    end
  end

  context "when no end user signups occurred this month" do
    before do
      allow(repository).to receive(:month_to_date_end_user_signups).with(date: today).and_return(
        run_time: "2026-07-17",
        total: 0,
      )
    end

    it "returns zero count" do
      expect(use_case.fetch_stats).to eq(
        count: 0,
        run_time: "2026-07-17",
        metric_name: "service-report-end-user-signups-mtd-count",
        period: "day",
        date: "2026-07-17",
      )
    end
  end

  context "when repository returns nil" do
    before do
      allow(repository).to receive(:month_to_date_end_user_signups).with(date: today).and_return(nil)
    end

    it "handles nil gracefully and defaults to 0 and date string" do
      expect(use_case.fetch_stats).to eq(
        count: 0,
        run_time: "2026-07-17",
        metric_name: "service-report-end-user-signups-mtd-count",
        period: "day",
        date: "2026-07-17",
      )
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

describe Performance::Repository::Organisation do
  let(:today) { Date.parse("2026-07-17") }

  before do
    Organisation.destroy_all
  end

  describe ".month_to_date_organisations_added" do
    context "with organisations added this month up to date" do
      before do
        create(:organisation, created_at: Date.new(today.year, today.month, 1))
        create(:organisation, created_at: today)
      end

      it "counts all organisations created between start of month and date" do
        result = described_class.month_to_date_organisations_added(date: today)
        expect(result).to eq(
          run_time: "2026-07-17",
          total: 2,
        )
      end
    end

    context "with organisations added outside current month" do
      before do
        create(:organisation, created_at: Date.new(today.year, today.month, 1) - 1.day)
        create(:organisation, created_at: today)
      end

      it "only counts organisations created within the current month" do
        result = described_class.month_to_date_organisations_added(date: today)
        expect(result[:total]).to eq(1)
      end
    end

    context "with organisations added after the specified date" do
      before do
        create(:organisation, created_at: today)
        create(:organisation, created_at: today + 2.days)
      end

      it "ignores organisations created after the specified date" do
        result = described_class.month_to_date_organisations_added(date: today)
        expect(result[:total]).to eq(1)
      end
    end

    context "with an empty organisations table" do
      it "returns total 0" do
        result = described_class.month_to_date_organisations_added(date: today)
        expect(result).to eq(
          run_time: "2026-07-17",
          total: 0,
        )
      end
    end
  end

  describe ".monthly_rolling_window_organisations_added" do
    context "with organisations added within the 30-day rolling window" do
      before do
        create(:organisation, created_at: today - 10.days)
        create(:organisation, created_at: today - 5.days)
        create(:organisation, created_at: today - 1.day)
        create(:organisation, created_at: today - 31.days)
      end

      it "counts organisations created between today - 31 days and today - 1 day" do
        result = described_class.monthly_rolling_window_organisations_added(date: today)
        expect(result).to eq(
          run_time: "2026-07-17",
          total: 4,
        )
      end
    end

    context "with organisations added today (outside window)" do
      before do
        create(:organisation, created_at: today)
        create(:organisation, created_at: today - 1.day)
      end

      it "does not count organisations created today" do
        result = described_class.monthly_rolling_window_organisations_added(date: today)
        expect(result[:total]).to eq(1)
      end
    end

    context "with organisations added older than 31 days" do
      before do
        create(:organisation, created_at: today - 32.days)
        create(:organisation, created_at: today - 15.days)
      end

      it "ignores organisations older than 31 days" do
        result = described_class.monthly_rolling_window_organisations_added(date: today)
        expect(result[:total]).to eq(1)
      end
    end

    context "with an empty organisations table" do
      it "returns total 0" do
        result = described_class.monthly_rolling_window_organisations_added(date: today)
        expect(result).to eq(
          run_time: "2026-07-17",
          total: 0,
        )
      end
    end
  end
end

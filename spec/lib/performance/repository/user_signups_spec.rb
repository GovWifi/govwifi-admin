# frozen_string_literal: true

require "rails_helper"

describe Performance::Repository::UserSignups do
  let(:today) { Date.parse("2026-07-17") }

  before do
    WifiUser.delete_all
  end

  describe ".month_to_date_end_user_signups" do
    context "with end user signups this month up to date (including email, SMS, and sponsored)" do
      before do
        create(:wifi_user, username: "user01", contact: "alice@gov.uk", sponsor: "alice@gov.uk", created_at: Date.new(today.year, today.month, 1))
        create(:wifi_user, :phone_contact, username: "user02", created_at: today - 2.days)
        create(:wifi_user, username: "user03", contact: "guest@example.com", sponsor: "host@gov.uk", created_at: today.to_time.change(hour: 23, min: 59))
      end

      it "counts all users created between start of month and end of date" do
        result = described_class.month_to_date_end_user_signups(date: today)
        expect(result).to eq(
          run_time: "2026-07-17",
          total: 3,
        )
      end
    end

    context "with signups outside current month or after specified date" do
      before do
        create(:wifi_user, username: "prev01", created_at: Date.new(today.year, today.month, 1) - 1.day)
        create(:wifi_user, username: "curr01", created_at: today)
        create(:wifi_user, username: "futr01", created_at: today + 1.day)
      end

      it "only counts users created within the current month up to the specified date" do
        result = described_class.month_to_date_end_user_signups(date: today)
        expect(result[:total]).to eq(1)
      end
    end

    context "with an empty userdetails table" do
      it "returns total 0" do
        result = described_class.month_to_date_end_user_signups(date: today)
        expect(result).to eq(
          run_time: "2026-07-17",
          total: 0,
        )
      end
    end

    it "handles nil query result gracefully" do
      fake_connection = instance_double(ActiveRecord::ConnectionAdapters::AbstractAdapter)
      allow(::WifiUser).to receive(:connection).and_return(fake_connection)
      allow(fake_connection).to receive(:select_one).and_return(nil)

      expect(described_class.month_to_date_end_user_signups(date: today)).to be_nil
    end
  end

  describe ".monthly_rolling_window_end_user_signups" do
    context "with end user signups within the 30-day rolling window" do
      before do
        create(:wifi_user, username: "user01", created_at: today - 30.days)
        create(:wifi_user, :phone_contact, username: "user02", created_at: today - 10.days)
        create(:wifi_user, username: "user03", contact: "guest@example.com", sponsor: "host@gov.uk", created_at: today - 5.days)
        create(:wifi_user, username: "user04", created_at: (today - 1.day).to_time.change(hour: 23, min: 59))
      end

      it "counts users created from today - 30 days up to the end of yesterday" do
        result = described_class.monthly_rolling_window_end_user_signups(date: today)
        expect(result).to eq(
          run_time: "2026-07-17",
          total: 4,
        )
      end
    end

    context "with signups outside the 30-day rolling window" do
      before do
        create(:wifi_user, username: "old001", created_at: today - 31.days)
        create(:wifi_user, username: "inwin1", created_at: today - 15.days)
        create(:wifi_user, username: "today1", created_at: today)
      end

      it "ignores signups older than 30 days or created today" do
        result = described_class.monthly_rolling_window_end_user_signups(date: today)
        expect(result[:total]).to eq(1)
      end
    end

    it "handles nil query result gracefully" do
      fake_connection = instance_double(ActiveRecord::ConnectionAdapters::AbstractAdapter)
      allow(::WifiUser).to receive(:connection).and_return(fake_connection)
      allow(fake_connection).to receive(:select_one).and_return(nil)

      expect(described_class.monthly_rolling_window_end_user_signups(date: today)).to be_nil
    end
  end

  describe ".month_to_date_email_signups" do
    context "with email and SMS signups this month" do
      before do
        create(:wifi_user, username: "em0001", contact: "self@gov.uk", sponsor: "self@gov.uk", created_at: Date.new(today.year, today.month, 1))
        create(:wifi_user, username: "em0002", contact: "sponsored@example.com", sponsor: "host@gov.uk", created_at: today.to_time.change(hour: 23, min: 59))
        create(:wifi_user, :phone_contact, username: "sm0001", created_at: today)
        create(:wifi_user, username: "emprev", contact: "old@gov.uk", created_at: Date.new(today.year, today.month, 1) - 1.day)
        create(:wifi_user, username: "emfutr", contact: "future@gov.uk", created_at: today + 1.day)
      end

      it "counts only email signups (including sponsored email users) within the current month up to date" do
        result = described_class.month_to_date_email_signups(date: today)
        expect(result).to eq(
          run_time: "2026-07-17",
          total: 2,
        )
      end
    end

    it "handles nil query result gracefully" do
      fake_connection = instance_double(ActiveRecord::ConnectionAdapters::AbstractAdapter)
      allow(::WifiUser).to receive(:connection).and_return(fake_connection)
      allow(fake_connection).to receive(:select_one).and_return(nil)

      expect(described_class.month_to_date_email_signups(date: today)).to be_nil
    end
  end

  describe ".monthly_rolling_window_email_signups" do
    context "with email and SMS signups in the 30-day rolling window" do
      before do
        create(:wifi_user, username: "em0001", contact: "self@gov.uk", sponsor: "self@gov.uk", created_at: today - 30.days)
        create(:wifi_user, username: "em0002", contact: "sponsored@example.com", sponsor: "host@gov.uk", created_at: (today - 1.day).to_time.change(hour: 23, min: 59))
        create(:wifi_user, :phone_contact, username: "sm0001", created_at: today - 5.days)
        create(:wifi_user, username: "emold1", contact: "old@gov.uk", created_at: today - 31.days)
        create(:wifi_user, username: "emtod1", contact: "today@gov.uk", created_at: today)
      end

      it "counts only email signups within the 30-day rolling window" do
        result = described_class.monthly_rolling_window_email_signups(date: today)
        expect(result).to eq(
          run_time: "2026-07-17",
          total: 2,
        )
      end
    end

    it "handles nil query result gracefully" do
      fake_connection = instance_double(ActiveRecord::ConnectionAdapters::AbstractAdapter)
      allow(::WifiUser).to receive(:connection).and_return(fake_connection)
      allow(fake_connection).to receive(:select_one).and_return(nil)

      expect(described_class.monthly_rolling_window_email_signups(date: today)).to be_nil
    end
  end

  describe ".month_to_date_sms_signups" do
    context "with SMS and email signups this month" do
      before do
        create(:wifi_user, username: "sm0001", contact: "+447700900001", sponsor: "+447700900001", created_at: Date.new(today.year, today.month, 1))
        create(:wifi_user, username: "sm0002", contact: "+447700900002", sponsor: "host@gov.uk", created_at: today.to_time.change(hour: 23, min: 59))
        create(:wifi_user, username: "em0001", contact: "user@gov.uk", created_at: today)
        create(:wifi_user, username: "smprev", contact: "+447700900003", created_at: Date.new(today.year, today.month, 1) - 1.day)
        create(:wifi_user, username: "smfutr", contact: "+447700900004", created_at: today + 1.day)
      end

      it "counts only SMS signups (including sponsored SMS users) within the current month up to date" do
        result = described_class.month_to_date_sms_signups(date: today)
        expect(result).to eq(
          run_time: "2026-07-17",
          total: 2,
        )
      end
    end

    it "handles nil query result gracefully" do
      fake_connection = instance_double(ActiveRecord::ConnectionAdapters::AbstractAdapter)
      allow(::WifiUser).to receive(:connection).and_return(fake_connection)
      allow(fake_connection).to receive(:select_one).and_return(nil)

      expect(described_class.month_to_date_sms_signups(date: today)).to be_nil
    end
  end

  describe ".monthly_rolling_window_sms_signups" do
    context "with SMS and email signups in the 30-day rolling window" do
      before do
        create(:wifi_user, username: "sm0001", contact: "+447700900001", sponsor: "+447700900001", created_at: today - 30.days)
        create(:wifi_user, username: "sm0002", contact: "+447700900002", sponsor: "host@gov.uk", created_at: (today - 1.day).to_time.change(hour: 23, min: 59))
        create(:wifi_user, username: "em0001", contact: "user@gov.uk", created_at: today - 5.days)
        create(:wifi_user, username: "smold1", contact: "+447700900003", created_at: today - 31.days)
        create(:wifi_user, username: "smtod1", contact: "+447700900004", created_at: today)
      end

      it "counts only SMS signups within the 30-day rolling window" do
        result = described_class.monthly_rolling_window_sms_signups(date: today)
        expect(result).to eq(
          run_time: "2026-07-17",
          total: 2,
        )
      end
    end

    it "handles nil query result gracefully" do
      fake_connection = instance_double(ActiveRecord::ConnectionAdapters::AbstractAdapter)
      allow(::WifiUser).to receive(:connection).and_return(fake_connection)
      allow(fake_connection).to receive(:select_one).and_return(nil)

      expect(described_class.monthly_rolling_window_sms_signups(date: today)).to be_nil
    end
  end

  describe "consistency across End User, Email, and SMS signups" do
    before do
      create(:wifi_user, username: "em0001", contact: "self@gov.uk", sponsor: "self@gov.uk", created_at: today - 2.days)
      create(:wifi_user, username: "em0002", contact: "sponsored@example.com", sponsor: "host@gov.uk", created_at: today - 2.days)
      create(:wifi_user, username: "sm0001", contact: "+447700900001", sponsor: "+447700900001", created_at: today - 2.days)
      create(:wifi_user, username: "sm0002", contact: "+447700900002", sponsor: "host@gov.uk", created_at: today - 2.days)
    end

    it "ensures Email Signups + SMS Signups equals End User Signups for both MTD and rolling windows" do
      mtd_total = described_class.month_to_date_end_user_signups(date: today)[:total]
      mtd_email = described_class.month_to_date_email_signups(date: today)[:total]
      mtd_sms = described_class.month_to_date_sms_signups(date: today)[:total]

      rolling_total = described_class.monthly_rolling_window_end_user_signups(date: today)[:total]
      rolling_email = described_class.monthly_rolling_window_email_signups(date: today)[:total]
      rolling_sms = described_class.monthly_rolling_window_sms_signups(date: today)[:total]

      expect(mtd_email + mtd_sms).to eq(mtd_total)
      expect(rolling_email + rolling_sms).to eq(rolling_total)
    end
  end
end

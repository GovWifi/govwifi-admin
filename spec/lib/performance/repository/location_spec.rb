# frozen_string_literal: true

describe Performance::Repository::Location do
  describe ".month_to_date_locations_added" do
    let(:date) { Date.new(2026, 7, 17) }

    it "constructs a sanitized SQL query with bind parameters" do
      expect(::Location).to receive(:sanitize_sql_array).with([
        "SELECT
          DATE_FORMAT(?, '%Y-%m-%d') AS run_time,
          COUNT(id) AS total
        FROM
          locations
        WHERE
          created_at >= DATE_FORMAT(?, '%Y-%m-01')
        AND
          created_at < ? + INTERVAL 1 DAY",
        "2026-07-17",
        "2026-07-17",
        "2026-07-17",
      ]).and_call_original

      described_class.month_to_date_locations_added(date:)
    end

    it "queries the database and returns symbol-keyed results" do
      fake_connection = instance_double(ActiveRecord::ConnectionAdapters::AbstractAdapter)
      allow(::Location).to receive(:connection).and_return(fake_connection)
      allow(fake_connection).to receive(:select_one).and_return({ "run_time" => "2026-07-17", "total" => 42 })

      result = described_class.month_to_date_locations_added(date:)
      expect(result).to eq({ run_time: "2026-07-17", total: 42 })
    end

    it "handles nil query result gracefully" do
      fake_connection = instance_double(ActiveRecord::ConnectionAdapters::AbstractAdapter)
      allow(::Location).to receive(:connection).and_return(fake_connection)
      allow(fake_connection).to receive(:select_one).and_return(nil)

      result = described_class.month_to_date_locations_added(date:)
      expect(result).to be_nil
    end

    it "formats string dates properly" do
      expect(::Location).to receive(:sanitize_sql_array).with(
        array_including("2026-07-17", "2026-07-17", "2026-07-17"),
      ).and_call_original

      described_class.month_to_date_locations_added(date: "2026-07-17")
    end
  end

  describe ".monthly_rolling_window_locations_added" do
    let(:date) { Date.new(2026, 7, 17) }

    it "constructs a sanitized SQL query with bind parameters for 30-day rolling window" do
      expect(::Location).to receive(:sanitize_sql_array).with([
        "SELECT
          DATE_FORMAT(?, '%Y-%m-%d') AS run_time,
          COUNT(id) AS total
        FROM
          locations
        WHERE
          created_at >= ? - INTERVAL 30 DAY
        AND
          created_at < ?",
        "2026-07-17",
        "2026-07-17",
        "2026-07-17",
      ]).and_call_original

      described_class.monthly_rolling_window_locations_added(date:)
    end

    it "queries the database and returns symbol-keyed results" do
      fake_connection = instance_double(ActiveRecord::ConnectionAdapters::AbstractAdapter)
      allow(::Location).to receive(:connection).and_return(fake_connection)
      allow(fake_connection).to receive(:select_one).and_return({ "run_time" => "2026-07-17", "total" => 99 })

      result = described_class.monthly_rolling_window_locations_added(date:)
      expect(result).to eq({ run_time: "2026-07-17", total: 99 })
    end

    it "handles nil query result gracefully" do
      fake_connection = instance_double(ActiveRecord::ConnectionAdapters::AbstractAdapter)
      allow(::Location).to receive(:connection).and_return(fake_connection)
      allow(fake_connection).to receive(:select_one).and_return(nil)

      result = described_class.monthly_rolling_window_locations_added(date:)
      expect(result).to be_nil
    end

    it "formats string dates properly" do
      expect(::Location).to receive(:sanitize_sql_array).with(
        array_including("2026-07-17", "2026-07-17", "2026-07-17"),
      ).and_call_original

      described_class.monthly_rolling_window_locations_added(date: "2026-07-17")
    end
  end
end

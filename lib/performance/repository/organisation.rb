# frozen_string_literal: true

module Performance::Repository
  class Organisation
    def self.month_to_date_organisations_added(date: Time.zone.today)
      date_str = format_date(date)
      sql = ::Organisation.sanitize_sql_array([
        "SELECT
          DATE_FORMAT(?, '%Y-%m-%d') AS run_time,
          COUNT(id) AS total
        FROM
          organisations
        WHERE
          created_at >= DATE_FORMAT(?, '%Y-%m-01')
        AND
          created_at < ? + INTERVAL 1 DAY",
        date_str,
        date_str,
        date_str,
      ])

      result = ::Organisation.connection.select_one(sql)
      result&.transform_keys(&:to_sym)
    end

    def self.monthly_rolling_window_organisations_added(date: Time.zone.today)
      date_str = format_date(date)
      sql = ::Organisation.sanitize_sql_array([
        "SELECT
          DATE_FORMAT(?, '%Y-%m-%d') AS run_time,
          COUNT(id) AS total
        FROM
          organisations
        WHERE
          created_at >= ? - INTERVAL 30 DAY
        AND
          created_at < ?",
        date_str,
        date_str,
        date_str,
      ])

      result = ::Organisation.connection.select_one(sql)
      result&.transform_keys(&:to_sym)
    end

    def self.format_date(date)
      (date.is_a?(Date) ? date : Date.parse(date.to_s)).strftime("%Y-%m-%d")
    end
    private_class_method :format_date
  end
end

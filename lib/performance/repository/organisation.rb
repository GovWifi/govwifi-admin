# frozen_string_literal: true

module Performance::Repository
  class Organisation
    def self.month_to_date_organisations_added(date: Time.zone.today)
      sql = "SELECT
              DATE_FORMAT('#{date}', '%Y-%m-%d') AS run_time,
              COUNT(id) AS total
            FROM
              organisations
            WHERE
              created_at BETWEEN DATE_FORMAT('#{date}', '%Y-%m-01') AND '#{date}'"

      result = ::Organisation.connection.select_one(sql)
      result&.transform_keys(&:to_sym)
    end

    def self.monthly_rolling_window_organisations_added(date: Time.zone.today)
      sql = "SELECT
              DATE_FORMAT('#{date}', '%Y-%m-%d') AS run_time,
              COUNT(id) AS total
            FROM
              organisations
            WHERE
              created_at BETWEEN '#{date}' - INTERVAL 31 DAY AND '#{date}' - INTERVAL 1 DAY"

      result = ::Organisation.connection.select_one(sql)
      result&.transform_keys(&:to_sym)
    end
  end
end

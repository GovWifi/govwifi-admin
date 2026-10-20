# frozen_string_literal: true

require "logger"

module Performance::Metrics
  class UserSignupsMetricSender
    STATS = {
      monthly_rolling_end_user_signups: Performance::UseCase::MonthlyRollingWindowEndUserSignups,
      month_to_date_end_user_signups: Performance::UseCase::MonthToDateEndUserSignups,
      monthly_rolling_email_signups: Performance::UseCase::MonthlyRollingWindowEmailSignups,
      month_to_date_email_signups: Performance::UseCase::MonthToDateEmailSignups,
      monthly_rolling_sms_signups: Performance::UseCase::MonthlyRollingWindowSmsSignups,
      month_to_date_sms_signups: Performance::UseCase::MonthToDateSmsSignups,
    }.freeze

    METRIC_NAMES = {
      monthly_rolling_end_user_signups: "service-report-end-user-signups-rolling-count",
      month_to_date_end_user_signups: "service-report-end-user-signups-mtd-count",
      monthly_rolling_email_signups: "service-report-email-signups-rolling-count",
      month_to_date_email_signups: "service-report-email-signups-mtd-count",
      monthly_rolling_sms_signups: "service-report-sms-signups-rolling-count",
      month_to_date_sms_signups: "service-report-sms-signups-mtd-count",
    }.freeze

    def initialize(metric:, period: "day", date: Time.zone.today, logger: Logger.new($stdout))
      raise ArgumentError unless STATS.key?(metric)

      @metric = metric
      @period = period
      @date = date
      @logger = logger
    end

    def to_s3
      return if stats.nil?

      s3_payload = {
        count: stats[:count],
        metric_name: stats[:metric_name],
        period: stats[:period],
        date: stats[:date],
      }

      Gateways::S3.new(bucket: ENV.fetch("S3_METRICS_BUCKET"), key: "#{folder}/#{filename}").write("#{s3_payload.to_json}\n")
    end

    def to_api
      if stats.nil?
        @logger.info("[#{key}] No stats to upload.")
        return
      end

      @logger.info("[#{key}] Contacting metrics API...")
      response = UseCases::PerformancePlatform::MetricsApiPublisher.publish(stats)

      if response&.success?
        @logger.info("[#{key}] Metrics API upload succeeded (status: #{response.status}).")
      elsif response
        @logger.warn("[#{key}] Metrics API upload failed (status: #{response.status}): #{response.body}")
      else
        @logger.warn("[#{key}] Metrics API upload failed: connection or other error.")
      end
    end

    def folder
      METRIC_NAMES.fetch(@metric)
    end

    def filename
      "#{folder}-#{@date}"
    end

    def key
      filename
    end

  private

    def stats
      @stats ||= STATS[@metric].new(period: @period, date: @date).fetch_stats
    end
  end
end

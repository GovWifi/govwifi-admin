# frozen_string_literal: true

require "faraday"
require "json"
require "logger"

module UseCases::PerformancePlatform
  class MetricsApiPublisher
    def self.publish(stats)
      return unless stats

      stringified_stats = stats.transform_keys(&:to_s)
      datetime_val = stringified_stats["run_time"].to_s
      if datetime_val
        if datetime_val.match?(/\A\d{4}-\d{2}-\d{2}\z/)
          datetime_val = "#{datetime_val}T00:00:00Z"
        elsif !datetime_val.end_with?("Z")
          datetime_val = "#{datetime_val}Z"
        end
      end

      payload = {
        "name" => stringified_stats["metric_name"],
        "value" => stringified_stats["count"]&.to_s,
        "datetime" => datetime_val,
      }

      connection.post("v1/record") do |req|
        req.headers["Authorization"] = "Bearer #{ENV.fetch('METRICS_API_BEARER_TOKEN')}"
        req.headers["Content-Type"] = "application/json"
        req.body = payload.to_json
      end
    rescue Faraday::Error => e
      logger.warn("Metrics API request failed: #{e.message} (endpoint: #{ENV.fetch('METRICS_API_ENDPOINT', 'unknown')})")
      nil
    end

    def self.connection
      base_url = ENV.fetch("METRICS_API_ENDPOINT").chomp("/")
      if @connection && @connection.url_prefix.to_s.chomp("/") == base_url
        @connection
      else
        @connection = Faraday.new(url: base_url)
      end
    end

    class << self
      attr_writer :logger

      def logger
        @logger ||= Logger.new($stdout)
      end
    end
  end
end

# frozen_string_literal: true

require "logger"

module UseCases
  module Administrator
    class ImportHistoricalMetrics
      DUPLICATE_ERROR_PATTERN = /already exists/i

      def self.execute(
        file_path: Gateways::HistoricalReportingSpreadsheet::DEFAULT_FILE_PATH,
        spreadsheet_gateway: nil,
        publisher: UseCases::PerformancePlatform::MetricsApiPublisher,
        logger: Logger.new($stdout),
        dry_run: false
      )
        new(
          file_path:,
          spreadsheet_gateway:,
          publisher:,
          logger:,
          dry_run:,
        ).execute
      end

      def initialize(
        file_path: Gateways::HistoricalReportingSpreadsheet::DEFAULT_FILE_PATH,
        spreadsheet_gateway: nil,
        publisher: UseCases::PerformancePlatform::MetricsApiPublisher,
        logger: Logger.new($stdout),
        dry_run: false
      )
        @file_path = file_path
        @spreadsheet_gateway = spreadsheet_gateway || Gateways::HistoricalReportingSpreadsheet.new(file_path:)
        @publisher = publisher
        @logger = logger
        @dry_run = dry_run
      end

      def execute
        entries = @spreadsheet_gateway.entries
        summary = {
          total: entries.size,
          recorded: 0,
          skipped: 0,
          failed: 0,
        }

        @logger.info("Starting historical metrics import (#{entries.size} metric entries)...")

        entries.each do |entry|
          process_entry(entry, summary)
        end

        @logger.info(
          "Historical metrics import complete: total=#{summary[:total]}, " \
          "recorded=#{summary[:recorded]}, skipped=#{summary[:skipped]}, failed=#{summary[:failed]}",
        )

        summary
      end

      alias_method :publish, :execute
      alias_method :import, :execute

    private

      def process_entry(entry, summary)
        metric_name = entry[:metric_name]
        datetime = entry[:datetime]
        value = entry[:value]
        context_tag = "[#{metric_name} @ #{datetime}]"

        if @dry_run
          @logger.info("[DRY RUN] #{context_tag} Would record value=#{value}")
          summary[:recorded] += 1
          return
        end

        response = @publisher.publish(
          metric_name:,
          value:,
          datetime:,
        )

        if response&.success?
          summary[:recorded] += 1
          @logger.info("#{context_tag} Metrics API upload succeeded (status: #{response.status}, value: #{value}).")
        elsif duplicate_record_response?(response)
          summary[:skipped] += 1
          @logger.info("#{context_tag} Skipped existing metric record (not overwritten).")
        elsif response
          summary[:failed] += 1
          @logger.warn("#{context_tag} Metrics API upload failed (status: #{response.status}): #{response.body}")
        else
          summary[:failed] += 1
          @logger.warn("#{context_tag} Metrics API upload failed: connection or other error.")
        end
      end

      def duplicate_record_response?(response)
        return false unless response

        response.status == 409 ||
          (response.status == 422 && response.body.to_s.match?(DUPLICATE_ERROR_PATTERN))
      end
    end
  end
end

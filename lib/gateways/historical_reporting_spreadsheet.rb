# frozen_string_literal: true

require "date"
require "rexml/document"
require "zip"

module Gateways
  class HistoricalReportingSpreadsheet
    DEFAULT_FILE_PATH = "/Users/oisin/Downloads/GovWifi Monthly Reporting Figures.ods"
    NUMERIC_PATTERN = /\A-?\d+(\.\d+)?\z/
    MONTH_YEAR_PATTERN = /\A([A-Za-z]+)\s+(\d{4})\z/
    MAX_REPEATED_EMPTY_COLUMNS = 50

    SHEET_CONFIGS = [
      {
        name: "Archive",
        start_date: Date.new(2023, 1, 1),
        end_date: Date.new(2025, 10, 1),
      }.freeze,
      {
        name: "Monthly Analytics Reporting",
        start_date: Date.new(2025, 11, 1),
        end_date: Date.new(2026, 9, 1),
      }.freeze,
    ].freeze

    COLUMN_METRIC_MAPPINGS = {
      "Active Users" => {
        headers: ["Active Users"].freeze,
        metric_names: %w[
          monthly-rolling-window-total-active-users
          month-to-date-total-active-users
        ].freeze,
      }.freeze,
      "TLS Unique Users" => {
        headers: ["TLS Unique Users"].freeze,
        metric_names: %w[
          service-report-active-tls-user-rolling-count
          service-report-active-tls-user-mtd-count
        ].freeze,
      }.freeze,
      "PEAP Unique Users" => {
        headers: ["PEAP Unique Users"].freeze,
        metric_names: %w[
          service-report-peap-unique-users-rolling-count
          service-report-peap-unique-users-mtd-count
        ].freeze,
      }.freeze,
      "Unique Roaming Users" => {
        headers: ["Roaming Users", "Unique Roaming Users"].freeze,
        metric_names: %w[
          monthly-rolling-window-total-roaming-users
          month-to-date-total-roaming-users
        ].freeze,
      }.freeze,
      "End-user Signups" => {
        headers: ["End User Sign-ups", "End-user Signups", "End User Signups"].freeze,
        metric_names: %w[
          service-report-end-user-signups-rolling-count
          service-report-end-user-signups-mtd-count
        ].freeze,
      }.freeze,
      "Email Signups" => {
        headers: ["Email Signups", "Email Sigups", "Email signups"].freeze,
        metric_names: %w[
          service-report-email-signups-rolling-count
          service-report-email-signups-mtd-count
        ].freeze,
      }.freeze,
      "SMS Signups" => {
        headers: ["SMS signups", "SMS Signups"].freeze,
        metric_names: %w[
          service-report-sms-signups-rolling-count
          service-report-sms-signups-mtd-count
        ].freeze,
      }.freeze,
      "Organisations Added" => {
        headers: ["Organisation Added", "Organisations Added"].freeze,
        metric_names: %w[
          service-report-organisations-addeded-rolling-count
          service-report-organisations-addeded-mtd-count
        ].freeze,
      }.freeze,
      "Locations Added" => {
        headers: ["Locations Added", "Location Added"].freeze,
        metric_names: %w[
          service-report-locations-added-rolling-count
          service-report-locations-added-mtd-count
        ].freeze,
      }.freeze,
    }.freeze

    def initialize(file_path: DEFAULT_FILE_PATH)
      @file_path = file_path
    end

    def entries
      validate_file_exists!
      document = read_ods_document

      SHEET_CONFIGS.flat_map do |sheet_config|
        extract_sheet_entries(document, sheet_config)
      end
    end

  private

    def validate_file_exists!
      return if @file_path && File.exist?(@file_path)

      raise ArgumentError, "Spreadsheet file not found: #{@file_path}"
    end

    def read_ods_document
      xml_content = Zip::File.open(@file_path) do |zip_file|
        entry = zip_file.find_entry("content.xml")
        raise ArgumentError, "Invalid ODS file #{@file_path}: missing content.xml" unless entry

        entry.get_input_stream.read
      end

      REXML::Document.new(xml_content)
    rescue Zip::Error => e
      raise ArgumentError, "Invalid ODS archive #{@file_path}: #{e.message}"
    rescue REXML::ParseException => e
      raise ArgumentError, "Invalid XML in ODS file #{@file_path}: #{e.message}"
    end

    def extract_sheet_entries(document, sheet_config)
      sheet_name = sheet_config[:name]
      table = find_worksheet(document, sheet_name)
      raise ArgumentError, "Missing required worksheet: '#{sheet_name}'" unless table

      rows = table.get_elements("table:table-row")
      raise ArgumentError, "Worksheet '#{sheet_name}' is empty" if rows.empty?

      header_cells = extract_row_cells(rows.first)
      column_indices = resolve_column_indices(header_cells, sheet_name)

      rows.drop(1).flat_map do |row_element|
        cells = extract_row_cells(row_element)
        extract_row_entries(cells, column_indices, sheet_config)
      end
    end

    def find_worksheet(document, sheet_name)
      document.get_elements("//table:table").find do |table|
        table_name = table.attributes["table:name"] || table.attributes["name"]
        table_name == sheet_name
      end
    end

    def resolve_column_indices(header_cells, sheet_name)
      normalized_headers = header_cells.map { |cell| normalize_header(cell[:text]) }

      COLUMN_METRIC_MAPPINGS.each_with_object({}) do |(canonical_name, mapping), indices|
        candidate_headers = mapping[:headers].map { |header| normalize_header(header) }
        column_index = normalized_headers.find_index { |header| candidate_headers.include?(header) }

        if column_index.nil?
          raise ArgumentError, "Missing required column '#{canonical_name}' in worksheet '#{sheet_name}'"
        end

        indices[canonical_name] = column_index
      end
    end

    def extract_row_entries(cells, column_indices, sheet_config)
      return [] if cells.empty?

      month_label = cells.first[:text].to_s.strip
      month_date = parse_month_label(month_label)
      return [] unless month_date
      return [] unless (sheet_config[:start_date]..sheet_config[:end_date]).cover?(month_date)

      datetime = month_date.strftime("%Y-%m-%dT00:00:00Z")
      sheet_name = sheet_config[:name]

      column_indices.flat_map do |canonical_name, col_idx|
        cell = cells[col_idx]
        value = extract_numeric_value(cell, canonical_name:, month_label:, sheet_name:)
        next [] if value.nil?

        COLUMN_METRIC_MAPPINGS.fetch(canonical_name)[:metric_names].map do |metric_name|
          {
            sheet: sheet_name,
            month: month_label,
            column: canonical_name,
            metric_name:,
            value:,
            datetime:,
          }
        end
      end
    end

    def extract_row_cells(row_element)
      row_element.get_elements("table:table-cell").flat_map do |cell_element|
        repeat_attr = cell_element.attributes["table:number-columns-repeated"] ||
          cell_element.attributes["number-columns-repeated"]
        repeat_count = repeat_attr ? repeat_attr.to_i : 1

        text = cell_element.get_elements("text:p").map(&:text).compact.join(" ").strip
        office_value = cell_element.attributes["office:value"] || cell_element.attributes["value"]
        value_type = cell_element.attributes["office:value-type"] || cell_element.attributes["value-type"]

        cell_data = {
          text:,
          office_value: office_value&.strip,
          value_type: value_type&.strip,
        }

        if repeat_count > MAX_REPEATED_EMPTY_COLUMNS && text.empty? && office_value.nil?
          []
        else
          Array.new([repeat_count, MAX_REPEATED_EMPTY_COLUMNS].min, cell_data)
        end
      end
    end

    def parse_month_label(label)
      match = label.match(MONTH_YEAR_PATTERN)
      return nil unless match

      month_name = match[1]
      year = match[2].to_i
      month_index = Date::MONTHNAMES.index { |name| name&.casecmp?(month_name) } ||
        Date::ABBR_MONTHNAMES.index { |name| name&.casecmp?(month_name) }
      return nil unless month_index

      Date.new(year, month_index, 1)
    end

    def extract_numeric_value(cell, canonical_name:, month_label:, sheet_name:)
      return nil if cell.nil?

      raw_text = cell[:text].to_s.strip
      raw_office_value = cell[:office_value].to_s.strip

      return nil if raw_text.empty? && raw_office_value.empty?

      candidate = if cell[:value_type] == "float" && !raw_office_value.empty?
                    raw_office_value
                  elsif !raw_text.empty?
                    raw_text.delete(",")
                  else
                    raw_office_value
                  end

      unless candidate.match?(NUMERIC_PATTERN)
        raise ArgumentError,
              "Invalid numeric value '#{raw_text.empty? ? candidate : raw_text}' for '#{canonical_name}' in #{month_label} (#{sheet_name})"
      end

      normalize_number_string(candidate)
    end

    def normalize_number_string(number_str)
      return number_str unless number_str.include?(".")

      stripped = number_str.sub(/\.0+\z/, "")
      stripped == "-0" ? "0" : stripped
    end

    def normalize_header(header)
      header.to_s.strip.downcase.gsub(/\s+/, " ")
    end
  end
end

# frozen_string_literal: true

require "rails_helper"
require "tempfile"
require "zip"

describe Gateways::HistoricalReportingSpreadsheet do
  subject(:gateway) { described_class.new(file_path: ods_file.path) }

  let(:ods_file) { Tempfile.new(["historical_reporting", ".ods"]) }

  let(:standard_headers) do
    [
      "Month",
      "Active Users",
      "TLS Unique Users",
      "PEAP Unique Users",
      "Roaming Users",
      "End User Sign-ups",
      "Email Signups",
      "SMS signups",
      "Organisation Added",
      "Locations Added",
    ]
  end

  let(:archive_rows) do
    [
      standard_headers,
      ["December 2022", "400000", "0", "400000", "200000", "20000", "5000", "15000", "2", "10"],
      ["January 2023", "444000", "0", "444000", "243000", "26400", "", "", "5", "15"],
      ["June 2023", "534000", "0", "534000", "298000", "43700", "9840", "33200", "3", "-52"],
      ["October 2025", "869000", "8450", "860550", "539000", "62,200", "10300", "51000", "5", "10"],
      ["November 2025", "887000", "8590", "878410", "542000", "59400", "9640", "48800", "2", "25"],
    ]
  end

  let(:monthly_reporting_rows) do
    [
      ["Previous 12 Months", *standard_headers.drop(1)],
      ["October 2025", "869000", "8450", "860550", "539000", "62200", "10300", "51000", "5", "10"],
      ["November 2025", "887000", "8590", "878410", "542000", "59400", "9640", "48800", "2", "25"],
      ["September 2026", "980000", "13400", "966600", "636000", "69400", "10400", "58100", "6", "20"],
      ["October 2026", "1020000", "14600", "1005400", "633000", "77900", "13100", "64000", "5", "33"],
      ["£0.00", "-100.00%", "#DIV/0!", "#DIV/0!", "#DIV/0!"],
    ]
  end

  after do
    ods_file.close!
  end

  def build_ods_xml(sheets)
    sheet_fragments = sheets.map do |sheet_name, rows|
      row_fragments = rows.map do |row|
        cell_fragments = row.map do |cell|
          if cell.is_a?(Hash)
            attrs = cell.fetch(:attrs, {}).map { |k, v| %(#{k}="#{v}") }.join(" ")
            text_val = cell[:text]
            inner = text_val ? "<text:p>#{text_val}</text:p>" : ""
            "<table:table-cell #{attrs}>#{inner}</table:table-cell>"
          elsif cell.to_s.empty?
            "<table:table-cell/>"
          else
            "<table:table-cell office:value-type=\"string\"><text:p>#{cell}</text:p></table:table-cell>"
          end
        end
        "<table:table-row>#{cell_fragments.join}</table:table-row>"
      end
      %(<table:table table:name="#{sheet_name}">#{row_fragments.join}</table:table>)
    end

    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <office:document-content
        xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
        xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
        xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0">
        <office:body>
          <office:spreadsheet>
            #{sheet_fragments.join}
          </office:spreadsheet>
        </office:body>
      </office:document-content>
    XML
  end

  def write_ods_file(xml_content)
    File.unlink(ods_file.path) if File.exist?(ods_file.path)
    Zip::File.open(ods_file.path, create: true) do |zip|
      zip.get_output_stream("content.xml") { |os| os.write(xml_content) }
    end
  end

  describe "#entries" do
    before do
      write_ods_file(
        build_ods_xml(
          "Archive" => archive_rows,
          "Monthly Analytics Reporting" => monthly_reporting_rows,
        ),
      )
    end

    it "extracts only rows within January 2023..October 2025 from Archive and November 2025..September 2026 from Monthly Analytics Reporting" do
      entries = gateway.entries

      archive_months = entries.select { |e| e[:sheet] == "Archive" }.map { |e| e[:month] }.uniq
      recent_months = entries.select { |e| e[:sheet] == "Monthly Analytics Reporting" }.map { |e| e[:month] }.uniq

      expect(archive_months).to eq(["January 2023", "June 2023", "October 2025"])
      expect(recent_months).to eq(["November 2025", "September 2026"])
    end

    it "formats each monthly timestamp as the first day of the month at 00:00:00Z" do
      datetimes = gateway.entries.map { |e| e[:datetime] }.uniq

      expect(datetimes).to eq([
        "2023-01-01T00:00:00Z",
        "2023-06-01T00:00:00Z",
        "2025-10-01T00:00:00Z",
        "2025-11-01T00:00:00Z",
        "2026-09-01T00:00:00Z",
      ])
    end

    describe "column-to-metric mapping for all 9 Tableau metrics (rolling and MTD)" do
      {
        "Active Users" => %w[
          monthly-rolling-window-total-active-users
          month-to-date-total-active-users
          887000
        ],
        "TLS Unique Users" => %w[
          service-report-active-tls-user-rolling-count
          service-report-active-tls-user-mtd-count
          8590
        ],
        "PEAP Unique Users" => %w[
          service-report-peap-unique-users-rolling-count
          service-report-peap-unique-users-mtd-count
          878410
        ],
        "Unique Roaming Users" => %w[
          monthly-rolling-window-total-roaming-users
          month-to-date-total-roaming-users
          542000
        ],
        "End-user Signups" => %w[
          service-report-end-user-signups-rolling-count
          service-report-end-user-signups-mtd-count
          59400
        ],
        "Email Signups" => %w[
          service-report-email-signups-rolling-count
          service-report-email-signups-mtd-count
          9640
        ],
        "SMS Signups" => %w[
          service-report-sms-signups-rolling-count
          service-report-sms-signups-mtd-count
          48800
        ],
        "Organisations Added" => %w[
          service-report-organisations-addeded-rolling-count
          service-report-organisations-addeded-mtd-count
          2
        ],
        "Locations Added" => %w[
          service-report-locations-added-rolling-count
          service-report-locations-added-mtd-count
          25
        ],
      }.each do |column_name, (rolling_metric, mtd_metric, expected_value)|
        it "maps '#{column_name}' to #{rolling_metric} and #{mtd_metric}" do
          nov_entries = gateway.entries.select do |entry|
            entry[:datetime] == "2025-11-01T00:00:00Z" && entry[:column] == column_name
          end

          expect(nov_entries).to eq([
            {
              sheet: "Monthly Analytics Reporting",
              month: "November 2025",
              column: column_name,
              metric_name: rolling_metric,
              value: expected_value,
              datetime: "2025-11-01T00:00:00Z",
            },
            {
              sheet: "Monthly Analytics Reporting",
              month: "November 2025",
              column: column_name,
              metric_name: mtd_metric,
              value: expected_value,
              datetime: "2025-11-01T00:00:00Z",
            },
          ])
        end
      end
    end

    it "skips blank cells without raising an error" do
      jan_2023_entries = gateway.entries.select { |e| e[:datetime] == "2023-01-01T00:00:00Z" }
      jan_2023_columns = jan_2023_entries.map { |e| e[:column] }.uniq

      expect(jan_2023_columns).not_to include("Email Signups", "SMS Signups")
      expect(jan_2023_entries.size).to eq(14)
    end

    it "imports negative numeric values as-is" do
      june_2023_locations = gateway.entries.select do |entry|
        entry[:datetime] == "2023-06-01T00:00:00Z" && entry[:column] == "Locations Added"
      end

      expect(june_2023_locations.map { |e| e[:value] }).to eq(["-52", "-52"])
    end

    it "strips thousands commas from formatted text values" do
      oct_2025_signups = gateway.entries.select do |entry|
        entry[:datetime] == "2025-10-01T00:00:00Z" && entry[:column] == "End-user Signups"
      end

      expect(oct_2025_signups.map { |e| e[:value] }).to eq(%w[62200 62200])
    end

    it "handles ODS repeated columns and float office:value attributes" do
      repeated_archive = [
        standard_headers,
        [
          "February 2023",
          {
            attrs: {
              "office:value-type" => "float",
              "office:value" => "469000.0",
              "table:number-columns-repeated" => "2",
            },
            text: "469,000",
          },
          "469000",
          "258000",
          "47700",
          {
            attrs: { "table:number-columns-repeated" => "2" },
            text: nil,
          },
          "6",
          "16",
          {
            attrs: { "table:number-columns-repeated" => "1024" },
            text: nil,
          },
        ],
      ]

      write_ods_file(
        build_ods_xml(
          "Archive" => repeated_archive,
          "Monthly Analytics Reporting" => [standard_headers],
        ),
      )

      feb_entries = gateway.entries
      active_user_val = feb_entries.find { |e| e[:column] == "Active Users" }[:value]
      tls_user_val = feb_entries.find { |e| e[:column] == "TLS Unique Users" }[:value]

      expect(active_user_val).to eq("469000")
      expect(tls_user_val).to eq("469000")
      expect(feb_entries.map { |e| e[:column] }).not_to include("Email Signups", "SMS Signups")
    end
  end

  describe "error and failure handling" do
    it "raises ArgumentError when the spreadsheet file does not exist" do
      missing_gateway = described_class.new(file_path: "/nonexistent/path/figures.ods")

      expect { missing_gateway.entries }.to raise_error(
        ArgumentError,
        %r{Spreadsheet file not found: /nonexistent/path/figures\.ods},
      )
    end

    it "raises ArgumentError when the file is not a valid ZIP archive" do
      File.write(ods_file.path, "not a zip file")

      expect { gateway.entries }.to raise_error(
        ArgumentError,
        /Invalid ODS archive/,
      )
    end

    it "raises ArgumentError when content.xml is missing from the ODS archive" do
      File.unlink(ods_file.path) if File.exist?(ods_file.path)
      Zip::File.open(ods_file.path, create: true) do |zip|
        zip.get_output_stream("meta.xml") { |os| os.write("<meta/>") }
      end

      expect { gateway.entries }.to raise_error(
        ArgumentError,
        /missing content\.xml/,
      )
    end

    it "raises ArgumentError when content.xml contains malformed XML" do
      write_ods_file("<office:document-content><unclosed>")

      expect { gateway.entries }.to raise_error(
        ArgumentError,
        /Invalid XML in ODS file/,
      )
    end

    it "raises ArgumentError when a required worksheet is missing" do
      write_ods_file(build_ods_xml("Archive" => archive_rows))

      expect { gateway.entries }.to raise_error(
        ArgumentError,
        /Missing required worksheet: 'Monthly Analytics Reporting'/,
      )
    end

    it "raises ArgumentError when a worksheet has no rows" do
      write_ods_file(
        build_ods_xml(
          "Archive" => [],
          "Monthly Analytics Reporting" => monthly_reporting_rows,
        ),
      )

      expect { gateway.entries }.to raise_error(
        ArgumentError,
        /Worksheet 'Archive' is empty/,
      )
    end

    it "raises ArgumentError when a required column header is missing" do
      incomplete_headers = standard_headers.reject { |h| h == "Locations Added" }
      write_ods_file(
        build_ods_xml(
          "Archive" => [incomplete_headers],
          "Monthly Analytics Reporting" => monthly_reporting_rows,
        ),
      )

      expect { gateway.entries }.to raise_error(
        ArgumentError,
        /Missing required column 'Locations Added' in worksheet 'Archive'/,
      )
    end

    it "raises ArgumentError when a target cell contains a non-numeric value" do
      corrupt_archive = [
        standard_headers,
        ["January 2023", "#DIV/0!", "0", "444000", "243000", "26400", "", "", "5", "15"],
      ]
      write_ods_file(
        build_ods_xml(
          "Archive" => corrupt_archive,
          "Monthly Analytics Reporting" => monthly_reporting_rows,
        ),
      )

      expect { gateway.entries }.to raise_error(
        ArgumentError,
        /Invalid numeric value '#DIV\/0!' for 'Active Users' in January 2023 \(Archive\)/,
      )
    end
  end
end

require "csv"
class UploadForm
  include ActiveModel::Model
  include ActiveModel::Validations
  include BulkUpload::AddressHeaders

  validate :validate_reading_csv
  validate :validate_csv
  validate :validate_data_present
  validate :validate_header

  def validate_reading_csv
    result = CSV.read(upload_file, headers: true)
    @data ||= result.to_a[1..]
    @headers ||= result.headers
  rescue TypeError
    errors.add(:upload_file, :csv_error, message: "Choose a file before uploading")
  rescue CSV::MalformedCSVError, CSV::Parser::InvalidEncoding
    errors.add(:upload_file, :csv_error, message: "File must be csv format")
  end

  def validate_csv
    errors.add(:upload_file, :csv_error, message: "Invalid data structure") unless csv_valid?
  end

  def validate_data_present
    errors.add(:upload_file, :csv_error, message: "File has no data") if first_row_empty?
  end

  def validate_header
    errors.add(:upload_file, :csv_error, message: "File must use correct header names") if headers_match?
  end

  def self.build_address(row)
    "#{row[ADDRESS_LINE_1]}
    #{row[ADDRESS_LINE_2]}
    #{row[ADDRESS_LINE_3]}
    #{row[CITY]}
    #{row[COUNTY]}".squish
  end

  attr_accessor :upload_file, :data

private

  def headers_match?
    return false if @data.nil?

    headers_in_csv = @headers[0..HEADER_COLS.length - 1].map(&:strip).map(&:downcase)

    headers_in_csv != HEADER_COLS.map(&:downcase)
  end

  def csv_valid?
    return false if @data.nil?

    @data.is_a?(Array) &&
      @data.all? { |row| row.is_a? Array } &&
      @data.all? { |row| row.length >= 2 }
  end

  def first_row_empty?
    return false if @data.nil?
    return true if @data[0].nil?

    @data[0].all?(&:blank?)
  end
end

module Gateways
  class S3
    DOMAIN_ALLOW_LIST = {
      bucket: ENV.fetch("S3_PRODUCT_PAGE_DATA_BUCKET"),
      key: ENV.fetch("S3_EMAIL_DOMAINS_OBJECT_KEY"),
    }.freeze
    DOMAIN_REGEXP = {
      bucket: ENV.fetch("S3_SIGNUP_ALLOWLIST_BUCKET"),
      key: ENV.fetch("S3_SIGNUP_ALLOWLIST_OBJECT_KEY"),
    }.freeze
    ORGANISATION_NAME_LIST = {
      bucket: ENV.fetch("S3_PRODUCT_PAGE_DATA_BUCKET"),
      key: ENV.fetch("S3_ORGANISATION_NAMES_OBJECT_KEY"),
    }.freeze
    LOCATION_IPS = {
      bucket: ENV.fetch("S3_PUBLISHED_LOCATIONS_IPS_BUCKET"),
      key: ENV.fetch("S3_PUBLISHED_LOCATIONS_IPS_OBJECT_KEY"),
    }.freeze
    RADIUS_IPS_ALLOW_LIST = {
      bucket: ENV.fetch("S3_PUBLISHED_LOCATIONS_IPS_BUCKET"),
      key: ENV.fetch("S3_ALLOWLIST_OBJECT_KEY"),
    }.freeze
    CERTIFICATES = {
      bucket: ENV.fetch("S3_CERTIFICATES_BUCKET"),
      key: ENV.fetch("S3_CERTIFICATES_OBJECT_KEY"),
    }.freeze

    def initialize(bucket:, key:)
      @bucket = bucket
      @key = key
      @client = Aws::S3::Client.new(config)
    end

    def write(data)
      body = data.is_a?(String) ? StringIO.new(data) : data
      client.put_object(
        body:,
        bucket:,
        key:,
      )
    end

    def read
      client.get_object(bucket:, key:).body.read
    end

  private

    DEFAULT_REGION = "eu-west-2".freeze

    attr_reader :bucket, :key, :client

    def config
      { region: DEFAULT_REGION }.merge(Rails.application.config.s3_aws_config)
    end
  end
end

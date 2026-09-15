describe UseCases::Administrator::PublishOrgsWithNoPhysicalAddressForIpCount do
  subject(:use_case) { described_class.new }

  let(:today) { Time.zone.local(2026, 7, 17) }
  let(:s3_key) do
    "account-health-orgs-with-no-physical-address-for-ip-count/account-health-orgs-with-no-physical-address-for-ip-count-2026-07-17"
  end
  let(:metrics_api_endpoint) { "https://metrics.test.example.com" }
  let(:api_endpoint) { "#{metrics_api_endpoint}/v1/record" }

  before do
    stub_request(:post, api_endpoint).to_return(status: 200, body: "", headers: {})
  end

  around do |example|
    original_endpoint = ENV["METRICS_API_ENDPOINT"]
    original_token = ENV["METRICS_API_BEARER_TOKEN"]
    ENV["METRICS_API_ENDPOINT"] = metrics_api_endpoint
    ENV["METRICS_API_BEARER_TOKEN"] = "test-token"
    Timecop.freeze(today) { example.run }
    ENV["METRICS_API_ENDPOINT"] = original_endpoint
    ENV["METRICS_API_BEARER_TOKEN"] = original_token
  end

  context "when an organisation has a location with postcode 'unknown' and address 'unknown'" do
    it "counts the organisation" do
      create(:location, postcode: "unknown", address: "unknown")

      use_case.publish

      expect(JSON.parse(Gateways::S3.new(bucket: ENV.fetch("S3_METRICS_BUCKET"), key: s3_key).read)).to eq(
        "count" => 1,
        "metric_name" => "account-health-orgs-with-no-physical-address-for-ip-count",
        "period" => "day",
        "date" => "2026-07-17",
      )
    end
  end

  context "when an organisation has multiple locations with no physical address" do
    it "counts the organisation only once" do
      organisation = create(:organisation)
      create(:location, organisation:, postcode: "unknown", address: "unknown")
      build(:location, organisation:, postcode: "", address: nil).save!(validate: false)

      use_case.publish

      expect(JSON.parse(Gateways::S3.new(bucket: ENV.fetch("S3_METRICS_BUCKET"), key: s3_key).read)["count"]).to eq(1)
    end
  end

  context "when an organisation has one valid location and one location with no physical address" do
    it "counts the organisation" do
      organisation = create(:organisation)
      create(:location, organisation:, postcode: "SW1A 1AA", address: "10 Downing Street")
      create(:location, organisation:, postcode: "unknown", address: "unknown")

      use_case.publish

      expect(JSON.parse(Gateways::S3.new(bucket: ENV.fetch("S3_METRICS_BUCKET"), key: s3_key).read)["count"]).to eq(1)
    end
  end

  context "when an organisation has empty postcode and nil address" do
    it "counts the organisation" do
      build(:location, postcode: "", address: nil).save!(validate: false)

      use_case.publish

      expect(JSON.parse(Gateways::S3.new(bucket: ENV.fetch("S3_METRICS_BUCKET"), key: s3_key).read)["count"]).to eq(1)
    end
  end

  context "when an organisation has case-insensitive 'UNKNOWN' values" do
    it "counts the organisation" do
      create(:location, postcode: "UNKNOWN", address: "Unknown")

      use_case.publish

      expect(JSON.parse(Gateways::S3.new(bucket: ENV.fetch("S3_METRICS_BUCKET"), key: s3_key).read)["count"]).to eq(1)
    end
  end

  context "when an organisation has only valid locations" do
    it "does not count the organisation" do
      create(:location, postcode: "SW1A 1AA", address: "10 Downing Street")

      use_case.publish

      expect(JSON.parse(Gateways::S3.new(bucket: ENV.fetch("S3_METRICS_BUCKET"), key: s3_key).read)["count"]).to eq(0)
    end
  end

  context "when an organisation has an unknown postcode but a valid address" do
    it "does not count the organisation" do
      create(:location, postcode: "unknown", address: "10 Downing Street")

      use_case.publish

      expect(JSON.parse(Gateways::S3.new(bucket: ENV.fetch("S3_METRICS_BUCKET"), key: s3_key).read)["count"]).to eq(0)
    end
  end

  context "when an organisation has a valid postcode but an unknown address" do
    it "does not count the organisation" do
      create(:location, postcode: "SW1A 1AA", address: "unknown")

      use_case.publish

      expect(JSON.parse(Gateways::S3.new(bucket: ENV.fetch("S3_METRICS_BUCKET"), key: s3_key).read)["count"]).to eq(0)
    end
  end

  context "when an organisation has no locations at all" do
    it "does not count the organisation" do
      create(:organisation)

      use_case.publish

      expect(JSON.parse(Gateways::S3.new(bucket: ENV.fetch("S3_METRICS_BUCKET"), key: s3_key).read)["count"]).to eq(0)
    end
  end

  context "when multiple organisations have qualifying locations" do
    it "aggregates the count across distinct organisations" do
      org1 = create(:organisation)
      org2 = create(:organisation)
      org3 = create(:organisation)

      # org1 has 2 incomplete locations (should count as 1)
      create(:location, organisation: org1, postcode: "unknown", address: "unknown")
      build(:location, organisation: org1, postcode: "", address: "").save!(validate: false)

      # org2 has 1 incomplete and 1 valid location (should count as 1)
      create(:location, organisation: org2, postcode: "unknown", address: "unknown")
      create(:location, organisation: org2, postcode: "SW1A 1AA", address: "10 Downing Street")

      # org3 has only valid locations (should not count)
      create(:location, organisation: org3, postcode: "EC1A 1BB", address: "123 High Street")

      use_case.publish

      expect(JSON.parse(Gateways::S3.new(bucket: ENV.fetch("S3_METRICS_BUCKET"), key: s3_key).read)["count"]).to eq(2)
    end
  end

  context "when no organisations qualify" do
    it "publishes a zero count rather than erroring" do
      use_case.publish

      expect(JSON.parse(Gateways::S3.new(bucket: ENV.fetch("S3_METRICS_BUCKET"), key: s3_key).read)["count"]).to eq(0)
    end
  end

  it "posts the count to the metrics api" do
    create(:location, postcode: "unknown", address: "unknown")

    use_case.publish

    expect(a_request(:post, api_endpoint).with(
             body: {
               "name" => "account-health-orgs-with-no-physical-address-for-ip-count",
               "value" => "1",
               "datetime" => "2026-07-17T00:00:00Z",
             }.to_json,
           )).to have_been_made
  end

  context "when the metrics api request fails" do
    it "does not raise an error" do
      stub_request(:post, api_endpoint).to_timeout
      create(:location, postcode: "unknown", address: "unknown")

      expect { use_case.publish }.not_to raise_error
    end
  end
end

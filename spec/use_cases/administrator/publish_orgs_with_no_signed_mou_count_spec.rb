describe UseCases::Administrator::PublishOrgsWithNoSignedMouCount do
  subject(:use_case) { described_class.new }

  let(:today) { Time.zone.local(2026, 7, 17) }

  let(:s3_key) { "account-health-orgs-with-no-signed-mou-count/orgs-with-no-signed-mou-count-2026-07-17" }
  let(:metrics_api_endpoint) { "https://metrics.test.example.com" }
  let(:api_endpoint) { "#{metrics_api_endpoint}/v1/record" }

  before do
    stub_request(:post, api_endpoint).to_return(status: 200, body: "", headers: {})
  end

  around do |example|
    original_endpoint = ENV["METRICS_API_ENDPOINT"]
    ENV["METRICS_API_ENDPOINT"] = metrics_api_endpoint
    Timecop.freeze(today) { example.run }
    ENV["METRICS_API_ENDPOINT"] = original_endpoint
  end

  def published_payload
    JSON.parse(Gateways::S3.new(bucket: ENV.fetch("S3_METRICS_BUCKET"), key: s3_key).read)
  end

  context "when an organisation has a signed MOU" do
    it "does not count it" do
      organisation = create(:organisation)
      create(:mou, organisation:)

      use_case.publish

      expect(published_payload["count"]).to eq(0)
    end
  end

  context "when an organisation has no signed MOU" do
    it "counts it" do
      create(:organisation)

      use_case.publish

      expect(published_payload["count"]).to eq(1)
    end
  end

  context "when an organisation has re-signed and has multiple MOUs" do
    it "counts it only once, and only as signed" do
      organisation = create(:organisation)
      create(:mou, organisation:)
      create(:mou, organisation:)

      use_case.publish

      expect(published_payload["count"]).to eq(0)
    end
  end

  context "when there is a mix of organisations with and without a signed MOU" do
    it "aggregates the count across organisations" do
      create(:organisation)
      create(:organisation)
      signed_organisation = create(:organisation)
      create(:mou, organisation: signed_organisation)

      use_case.publish

      expect(published_payload["count"]).to eq(2)
    end
  end

  context "when there are no organisations at all" do
    it "publishes a zero count rather than erroring" do
      use_case.publish

      expect(published_payload["count"]).to eq(0)
    end
  end

  it "writes the full payload shape to S3" do
    create(:organisation)

    use_case.publish

    expect(published_payload).to eq(
      "count" => 1,
      "metric_name" => "account-health-orgs-with-no-signed-mou-count",
      "period" => "day",
      "date" => "2026-07-17",
    )
  end

  it "posts the count to the metrics api" do
    create(:organisation)

    use_case.publish

    expect(a_request(:post, api_endpoint).with(
             body: {
               "name" => "account-health-orgs-with-no-signed-mou-count",
               "value" => "1",
               "datetime" => "2026-07-17T00:00:00Z",
             }.to_json,
           )).to have_been_made
  end

  context "when the metrics api request fails" do
    it "does not raise, and still writes to S3" do
      stub_request(:post, api_endpoint).to_timeout
      create(:organisation)

      expect { use_case.publish }.not_to raise_error
      expect(published_payload["count"]).to eq(1)
    end
  end
end

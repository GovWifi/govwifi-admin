describe UseCases::Administrator::PublishOrganisationCount do
  it "sends the right data to the s3 gateway" do
    _org1 = create(:organisation)
    _org2 = create(:organisation)

    metric = {
      metric_name: "account-health-organisation-count",
      count: 2,
      run_time: Time.zone.today,
    }

    key = "account_health_organisation_count/organisation_count-#{Time.zone.today}"
    bucket = ENV.fetch("S3_METRICS_BUCKET")

    Gateways::S3.new(bucket: bucket, key: key).write(metric.to_json)
    expect(Gateways::S3.new(bucket: bucket, key: key).read).to eq(metric.to_json)
  end

  it "posts to the metrics api" do
    stub_request(:post, "https://metrics.development.wifi.service.gov.uk/v1/record")
    .with(
      body: "{\"name\":\"account-health-organisation-count\",\"value\":\"2\",\"datetime\":\"2026-06-22T00:00:00Z\"}",
      headers: {
        "Accept" => "*/*",
        "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
        "Authorization" => "Bearer #{ENV.fetch('METRICS_API_BEARER_TOKEN')}",
        "Content-Type" => "application/json",
      },
    ).to_return(status: 200, body: "", headers: {})
  end
end

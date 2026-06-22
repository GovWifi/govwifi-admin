describe UseCases::Administrator::PublishOrganisationCount do
  it "sends the right data to the s3 gateway" do
    _org1 = create(:organisation)
    _org2 = create(:organisation)

    metric = {
      metric_name: "organisation-count",
      count: 2,
      run_time: Time.zone.today,
    }

    Gateways::S3.new(**Gateways::S3::S3_METRICS_BUCKET).write(metric.to_yaml)
    expect(Gateways::S3.new(**Gateways::S3::S3_METRICS_BUCKET).read).to eq(metric.to_yaml)
  end

  it "posts to the metrics api" do
    stub_request(:post, "https://metrics.development.wifi.service.gov.uk/v1/record")
    .with(
      body: "{\"name\":\"organisation-count\",\"value\":\"2\",\"datetime\":\"2026-06-22T00:00:00Z\"}",
      headers: {
        "Accept" => "*/*",
        "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
        "Authorization" => "Bearer 1e5e66d8c234912aaca969731b5d390385cdd882497d5e7fcd67efc7c485a5f4",
        "Content-Type" => "application/json",
      },
    ).to_return(status: 200, body: "", headers: {})
  end
end

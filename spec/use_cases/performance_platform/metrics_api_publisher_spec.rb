# frozen_string_literal: true

require "rails_helper"

describe UseCases::PerformancePlatform::MetricsApiPublisher do
  let(:metrics_api_endpoint) { "https://metrics.test.example.com" }
  let(:api_endpoint) { "#{metrics_api_endpoint}/v1/record" }
  let(:bearer_token) { "secret-token-123" }

  around do |example|
    original_endpoint = ENV["METRICS_API_ENDPOINT"]
    original_token = ENV["METRICS_API_BEARER_TOKEN"]
    ENV["METRICS_API_ENDPOINT"] = metrics_api_endpoint
    ENV["METRICS_API_BEARER_TOKEN"] = bearer_token
    example.run
    ENV["METRICS_API_ENDPOINT"] = original_endpoint
    ENV["METRICS_API_BEARER_TOKEN"] = original_token
  end

  before do
    described_class.instance_variable_set(:@connection, nil)
  end

  it "posts metrics with bearer authorization and JSON headers" do
    stub = stub_request(:post, api_endpoint).with(
      headers: {
        "Authorization" => "Bearer #{bearer_token}",
        "Content-Type" => "application/json",
      },
      body: {
        "name" => "service-report-organisations-addeded-mtd-count",
        "value" => "12500",
        "datetime" => "2026-05-19T16:04Z",
      }.to_json,
    ).to_return(status: 200, body: '{"status":"ok"}')

    stats = {
      metric_name: "service-report-organisations-addeded-mtd-count",
      count: 12_500,
      run_time: "2026-05-19T16:04Z",
    }

    response = described_class.publish(stats)
    expect(stub).to have_been_made
    expect(response.status).to eq(200)
  end

  it "appends T00:00:00Z when run_time is a simple date string YYYY-MM-DD" do
    stub = stub_request(:post, api_endpoint).with(
      body: {
        "name" => "service-report-organisations-addeded-rolling-count",
        "value" => "47073",
        "datetime" => "2026-07-17T00:00:00Z",
      }.to_json,
    ).to_return(status: 200, body: "")

    stats = {
      metric_name: "service-report-organisations-addeded-rolling-count",
      count: 47_073,
      run_time: "2026-07-17",
    }

    described_class.publish(stats)
    expect(stub).to have_been_made
  end

  it "accepts datetime and value keys as alternatives to run_time and count" do
    stub = stub_request(:post, api_endpoint).with(
      body: {
        "name" => "service-report-organisations-addeded-mtd-count",
        "value" => "12500",
        "datetime" => "2026-05-19T16:04Z",
      }.to_json,
    ).to_return(status: 200, body: "")

    stats = {
      "name" => "service-report-organisations-addeded-mtd-count",
      "value" => "12500",
      "datetime" => "2026-05-19T16:04Z",
      "metric_name" => "service-report-organisations-addeded-mtd-count",
    }

    described_class.publish(stats)
    expect(stub).to have_been_made
  end

  it "returns nil when given nil stats" do
    expect(described_class.publish(nil)).to be_nil
  end

  it "catches Faraday errors and returns nil without raising" do
    stub_request(:post, api_endpoint).to_timeout

    stats = {
      metric_name: "service-report-organisations-addeded-rolling-count",
      count: 10,
      run_time: "2026-07-17",
    }

    expect { described_class.publish(stats) }.not_to raise_error
    expect(described_class.publish(stats)).to be_nil
  end
end

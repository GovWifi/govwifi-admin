describe UseCases::Administrator::PublishOrgsWithDormantAdminsCount do
  subject(:use_case) { described_class.new }

  let(:today) { Time.zone.local(2026, 7, 17) }
  let(:dormant_sign_in) { 366.days.ago }
  let(:active_sign_in) { 1.day.ago }

  let(:s3_key) { "account-health-orgs-with-dormant-admins-count/orgs-with-dormant-admins-count-2026-07-17" }
  let(:metrics_api_endpoint) { "https://metrics.test.example.com" }
  let(:api_endpoint) { "#{metrics_api_endpoint}/v1/record" }

  def dormant_admin_membership(organisation:)
    create(:membership, organisation:, user: create(:user, last_sign_in_at: dormant_sign_in))
  end

  def active_admin_membership(organisation:)
    create(:membership, organisation:, user: create(:user, last_sign_in_at: active_sign_in))
  end

  def never_signed_in_admin_membership(organisation:)
    create(:membership, organisation:, user: create(:user, last_sign_in_at: nil))
  end

  def view_only_dormant_membership(organisation:)
    create(:membership, organisation:, can_manage_team: false, can_manage_locations: false,
                         user: create(:user, last_sign_in_at: dormant_sign_in))
  end

  before do
    stub_request(:post, api_endpoint).to_return(status: 200, body: "", headers: {})
  end

  around do |example|
    original_endpoint = ENV["METRICS_API_ENDPOINT"]
    ENV["METRICS_API_ENDPOINT"] = metrics_api_endpoint
    Timecop.freeze(today) { example.run }
    ENV["METRICS_API_ENDPOINT"] = original_endpoint
  end

  context "when an organisation has exactly one dormant admin" do
    it "counts it" do
      organisation = create(:organisation)
      dormant_admin_membership(organisation:)

      use_case.publish

      expect(JSON.parse(Gateways::S3.new(bucket: ENV.fetch("S3_METRICS_BUCKET"), key: s3_key).read)).to eq(
        "count" => 1,
        "metric_name" => "account-health-orgs-with-dormant-admins-count",
        "period" => "day",
        "date" => "2026-07-17",
      )
    end
  end

  context "when an organisation has two or more dormant admins" do
    it "does not count it" do
      organisation = create(:organisation)
      dormant_admin_membership(organisation:)
      dormant_admin_membership(organisation:)

      use_case.publish

      expect(JSON.parse(Gateways::S3.new(bucket: ENV.fetch("S3_METRICS_BUCKET"), key: s3_key).read)["count"]).to eq(0)
    end
  end

  context "when the dormant member does not have admin permissions" do
    it "does not count the organisation" do
      organisation = create(:organisation)
      view_only_dormant_membership(organisation:)

      use_case.publish

      expect(JSON.parse(Gateways::S3.new(bucket: ENV.fetch("S3_METRICS_BUCKET"), key: s3_key).read)["count"]).to eq(0)
    end
  end

  context "when the sole admin has signed in recently" do
    it "does not count the organisation" do
      organisation = create(:organisation)
      active_admin_membership(organisation:)

      use_case.publish

      expect(JSON.parse(Gateways::S3.new(bucket: ENV.fetch("S3_METRICS_BUCKET"), key: s3_key).read)["count"]).to eq(0)
    end
  end

  context "when the sole admin has never signed in" do
    it "counts the organisation as dormant" do
      organisation = create(:organisation)
      never_signed_in_admin_membership(organisation:)

      use_case.publish

      expect(JSON.parse(Gateways::S3.new(bucket: ENV.fetch("S3_METRICS_BUCKET"), key: s3_key).read)["count"]).to eq(1)
    end
  end

  context "when multiple organisations qualify" do
    it "aggregates the count across organisations" do
      dormant_admin_membership(organisation: create(:organisation))
      dormant_admin_membership(organisation: create(:organisation))
      active_admin_membership(organisation: create(:organisation))

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
    dormant_admin_membership(organisation: create(:organisation))

    use_case.publish

    expect(a_request(:post, api_endpoint).with(
      body: {
        "name" => "account-health-orgs-with-dormant-admins-count",
        "value" => "1",
        "datetime" => "2026-07-17T00:00:00Z",
      }.to_json,
    )).to have_been_made
  end

  context "when the metrics api request fails" do
    it "does not raise" do
      stub_request(:post, api_endpoint).to_timeout
      dormant_admin_membership(organisation: create(:organisation))

      expect { use_case.publish }.not_to raise_error
    end
  end
end

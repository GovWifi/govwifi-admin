describe UseCases::Administrator::PublishOrgsWithLessThanTwoAdminsCount do
  subject(:use_case) { described_class.new }

  let(:today) { Time.zone.local(2026, 7, 17) }

  let(:s3_key) do
    "account-health-orgs-with-less-than-two-admins-count/" \
      "orgs-with-less-than-two-admins-count-2026-07-17"
  end
  let(:metrics_api_endpoint) { "https://metrics.test.example.com" }
  let(:api_endpoint) { "#{metrics_api_endpoint}/v1/record" }

  def admin_membership(organisation:)
    create(:membership, organisation:, user: create(:user))
  end

  def view_only_membership(organisation:)
    create(:membership, organisation:, can_manage_team: false, can_manage_locations: false,
                        user: create(:user))
  end

  def manage_locations_only_membership(organisation:)
    create(:membership, organisation:, can_manage_team: false, can_manage_locations: true,
                        user: create(:user))
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

  def published_count
    JSON.parse(Gateways::S3.new(bucket: ENV.fetch("S3_METRICS_BUCKET"), key: s3_key).read)["count"]
  end

  context "when an organisation has only a non-admin membership" do
    it "is not counted, since the query inner-joins on admin memberships only" do
      organisation = create(:organisation)
      view_only_membership(organisation:)

      use_case.publish

      expect(published_count).to eq(0)
    end
  end

  context "when an organisation has exactly one admin" do
    it "counts it" do
      organisation = create(:organisation)
      admin_membership(organisation:)

      use_case.publish

      expect(published_count).to eq(1)
    end
  end

  context "when an organisation has exactly two admins" do
    it "does not count it" do
      organisation = create(:organisation)
      admin_membership(organisation:)
      admin_membership(organisation:)

      use_case.publish

      expect(published_count).to eq(0)
    end
  end

  context "when an organisation has three or more admins" do
    it "does not count it" do
      organisation = create(:organisation)
      admin_membership(organisation:)
      admin_membership(organisation:)
      admin_membership(organisation:)

      use_case.publish

      expect(published_count).to eq(0)
    end
  end

  context "when an org has one admin and one membership with only one of the two admin permissions" do
    it "does not count the partial-permission membership as an admin" do
      organisation = create(:organisation)
      admin_membership(organisation:)
      manage_locations_only_membership(organisation:)

      use_case.publish

      expect(published_count).to eq(1)
    end
  end

  context "when multiple organisations qualify" do
    it "aggregates the count across organisations" do
      admin_membership(organisation: create(:organisation))
      admin_membership(organisation: create(:organisation))

      two_admin_org = create(:organisation)
      admin_membership(organisation: two_admin_org)
      admin_membership(organisation: two_admin_org)

      use_case.publish

      expect(published_count).to eq(2)
    end
  end

  context "when no organisations exist" do
    it "publishes a zero count rather than erroring" do
      use_case.publish

      expect(published_count).to eq(0)
    end
  end

  it "publishes the exact expected S3 payload" do
    admin_membership(organisation: create(:organisation))

    use_case.publish

    expect(JSON.parse(Gateways::S3.new(bucket: ENV.fetch("S3_METRICS_BUCKET"), key: s3_key).read)).to eq(
      "count" => 1,
      "metric_name" => "account-health-orgs-with-less-than-two-admins-count",
      "period" => "day",
      "date" => "2026-07-17",
    )
  end

  it "posts the count to the metrics api" do
    admin_membership(organisation: create(:organisation))

    use_case.publish

    expect(a_request(:post, api_endpoint).with(
             body: {
               "name" => "account-health-orgs-with-less-than-two-admins-count",
               "value" => "1",
               "datetime" => "2026-07-17T00:00:00Z",
             }.to_json,
           )).to have_been_made
  end

  context "when the metrics api request fails" do
    it "does not raise" do
      stub_request(:post, api_endpoint).to_timeout
      admin_membership(organisation: create(:organisation))

      expect { use_case.publish }.not_to raise_error
    end
  end
end

describe UseCases::Administrator::PublishOrganisationCount do
  subject(:result) { Gateways::S3.new(**Gateways::S3::S3_METRICS_BUCKET).read }

  context "when organisation are added" do
    it "counts two entries" do
      organisation1 = create(:organisation)
      organisation2 = create(:organisation)

      run_time = Time.zone.today

      UseCases::Administrator::PublishOrganisationCount.new.publish
      expect(result).to eq("---\n:metric_name: organisation_count\n:count: 2\n:run_time: #{run_time}\n")
    end
  end
end

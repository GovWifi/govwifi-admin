describe UseCases::Administrator::PublishOrganisationNames do
  subject(:result) { Gateways::S3.new(**Gateways::S3::ORGANISATION_NAME_LIST).read }

  context "when no organisation names" do
    it "creates no allowlist" do
      UseCases::Administrator::PublishOrganisationNames.new.publish
      expect(result).to eq("--- []\n")
    end
  end

  context "when organisation names are added" do
    it "creates a allowlist with one entry" do
      organisation1 = create(:organisation)
      organisation2 = create(:organisation)

      UseCases::Administrator::PublishOrganisationNames.new.publish
      expect(result).to eq("---\n- #{organisation1.name}\n- #{organisation2.name}\n")
    end
  end
end

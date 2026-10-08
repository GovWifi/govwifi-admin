describe UseCases::AccountHealth::Checks do
  include AccountHealthHelpers

  before { allow_account_health_organisation_names }

  describe "no signed MoU" do
    it "applies to organisations with no MoU record" do
      unsigned = create(:organisation)
      create(:mou, organisation: create(:organisation))

      expect(described_class.new.organisation_ids(:no_signed_mou)).to eq([unsigned.id])
    end
  end
end

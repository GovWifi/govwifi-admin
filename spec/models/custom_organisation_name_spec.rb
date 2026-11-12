require "rails_helper"

RSpec.describe CustomOrganisationName, type: :model do
  describe "#display_name" do
    it "returns the name squished" do
      custom_org = build(:custom_organisation_name, name: "  Custom Org  ")
      expect(custom_org.display_name).to eq("Custom Org")
    end
  end
end

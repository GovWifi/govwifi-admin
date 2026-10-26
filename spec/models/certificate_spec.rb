RSpec.describe Certificate, type: :model do
  describe "#name=" do
    it "strips leading and trailing whitespace from the name" do
      certificate = Certificate.new
      certificate.name = "  My Cert  "
      expect(certificate.name).to eq("My Cert")
    end

    it "collapses repeated internal whitespace into single spaces" do
      certificate = Certificate.new
      certificate.name = "  My   Cert\tWith\nNewlines  "
      expect(certificate.name).to eq("My Cert With Newlines")
    end
  end
end

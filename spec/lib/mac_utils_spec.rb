RSpec.describe MacUtils do
  describe ".normalize" do
    it "normalises a MAC address with colons" do
      expect(described_class.normalize("b9:e0:ba:aa:08:7e")).to eq("B9-E0-BA-AA-08-7E")
    end

    it "normalises a MAC address with dashes" do
      expect(described_class.normalize("b9-e0-ba-aa-08-7e")).to eq("B9-E0-BA-AA-08-7E")
    end

    it "normalises a MAC address with no separators" do
      expect(described_class.normalize("b9e0baaa087e")).to eq("B9-E0-BA-AA-08-7E")
    end

    it "uppercases the result" do
      expect(described_class.normalize("b9:e0:ba:aa:08:7e")).to eq("B9-E0-BA-AA-08-7E")
    end

    it "returns nil for nil input" do
      expect(described_class.normalize(nil)).to be_nil
    end

    it "returns nil for blank input" do
      expect(described_class.normalize("")).to be_nil
      expect(described_class.normalize("  ")).to be_nil
    end

    it "handles a short MAC address" do
      expect(described_class.normalize("b9e0")).to eq("B9-E0")
    end
  end

  describe ".valid?" do
    it "returns true for a valid MAC address" do
      expect(described_class.valid?("b9:e0:ba:aa:08:7e")).to be true
    end

    it "returns true for a valid MAC address in hyphenated format" do
      expect(described_class.valid?("B9-E0-BA-AA-08-7E")).to be true
    end

    it "returns false for nil input" do
      expect(described_class.valid?(nil)).to be false
    end

    it "returns false for an invalid MAC address" do
      expect(described_class.valid?("not-a-mac")).to be false
    end
  end
end

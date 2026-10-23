require "rails_helper"

describe Mou do
  describe "#formatted_date" do
    it "formats the date as day month year" do
      mou = build(:mou, created_at: Time.zone.parse("2026-10-21 14:32:00"))
      expect(mou.formatted_date).to eq("21 October 2026")
    end
  end

  describe "#formatted_time" do
    it "formats the time with UTC suffix" do
      mou = build(:mou, created_at: Time.zone.parse("2026-10-21 14:32:00"))
      expect(mou.formatted_time).to eq("14:32 UTC")
    end
  end
end

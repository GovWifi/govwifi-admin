require "rails_helper"

describe MouForm do
  let(:organisation) { create(:organisation) }
  let(:user) { create(:user, organisations: [organisation]) }
  let(:mou_form) do
    described_class.new(
      name: "Test User",
      email_address: "test@example.gov.uk",
      job_role: "Developer",
      signed: "true",
    )
  end

  describe "#save!" do
    context "when re-signing is pending" do
      before do
        organisation.update!(mou_resign_required_at: Time.zone.now)
      end

      it "creates a new mou" do
        expect {
          mou_form.save!(organisation:, user:)
        }.to change(Mou, :count).by(1)
      end

      it "clears mou_resign_required_at" do
        mou_form.save!(organisation:, user:)
        expect(organisation.reload.mou_resign_required_at).to be_nil
      end

      it "preserves the existing mou" do
        existing_mou = create(:mou, organisation:, version: Mou.latest_known_version)
        mou_form.save!(organisation:, user:)
        expect(Mou.find_by(id: existing_mou.id)).to be_present
        expect(Mou.count).to eq(2)
      end

      it "wraps creation and flag clearing in a transaction" do
        allow(Mou).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)
        expect {
          mou_form.save!(organisation:, user:)
        }.to raise_error(ActiveRecord::RecordInvalid)
        expect(organisation.reload.mou_resign_required_at).to be_present
      end
    end

    context "when no re-sign is pending" do
      it "creates a new mou" do
        expect {
          mou_form.save!(organisation:, user:)
        }.to change(Mou, :count).by(1)
      end
    end
  end
end

require "rails_helper"

describe SettingsHelper do
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Context
  include GovukComponentsHelper

  let(:organisation) { create(:organisation) }

  describe "#mou_status_label" do
    context "when re-sign is pending and the organisation has signed before" do
      before do
        create(:mou, organisation:, name: "Test Signer", version: Mou.latest_known_version)
        organisation.update!(mou_resign_required_at: Time.zone.now)
      end

      it "shows Not signed with sign instructions" do
        label = helper.mou_status_label(organisation)
        expect(label).to include("Not signed")
      end
    end

    context "when the organisation has signed" do
      let(:mou) { create(:mou, organisation:, name: "Test Signer", version: Mou.latest_known_version) }

      before { mou }

      it "shows the signer name with date and time in UTC" do
        label = helper.mou_status_label(organisation)
        expect(label).to include("Signed by Test Signer")
        expect(label).to include("at")
        expect(label).to include("UTC")
      end
    end

    context "when the organisation has not signed" do
      it "shows Not signed" do
        label = helper.mou_status_label(organisation)
        expect(label).to include("Not signed")
      end
    end
  end

  describe "#mou_action" do
    context "when re-sign is pending" do
      before do
        create(:mou, organisation:, version: Mou.latest_known_version)
        organisation.update!(mou_resign_required_at: Time.zone.now)
      end

      it "returns Sign the MOU action" do
        action = helper.mou_action(organisation)
        expect(action[:text]).to eq("Sign the MOU")
        expect(action[:href]).to eq(show_options_mous_path)
      end
    end

    context "when the organisation has signed and no re-sign is pending" do
      before do
        create(:mou, organisation:, version: Mou.latest_known_version)
      end

      it "returns Review action linking to review page" do
        action = helper.mou_action(organisation)
        expect(action[:text]).to eq("Review")
        expect(action[:href]).to eq(review_mou_settings_path)
      end
    end

    context "when the organisation has not signed" do
      it "returns Sign the MOU action" do
        action = helper.mou_action(organisation)
        expect(action[:text]).to eq("Sign the MOU")
        expect(action[:href]).to eq(show_options_mous_path)
      end
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Timeout", type: :request do
  describe "GET /timeout/keep_alive" do
    context "when the user is signed in" do
      let(:user) { create(:user, :with_organisation) }

      before do
        sign_in user
        get timeout_keep_alive_path
      end

      it "returns success" do
        expect(response).to have_http_status(:ok)
      end

      it "returns an empty body" do
        expect(response.body).to be_empty
      end
    end

    context "when the user is not signed in" do
      before do
        get timeout_keep_alive_path
      end

      it "redirects to sign in" do
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /timeout/signed_out" do
    context "when the user is signed in" do
      let(:user) { create(:user, :with_organisation) }

      before do
        sign_in user
        get timeout_signed_out_path
      end

      it "returns success" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the signed_out template" do
        expect(response).to render_template(:signed_out)
      end

      it "signs the user out" do
        expect(controller.current_user).to be_nil
      end

      it "shows the signed out message" do
        expect(response.body).to include("For your security, we signed you out")
      end
    end

    context "when the user is not signed in" do
      before do
        get timeout_signed_out_path
      end

      it "returns success" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the signed_out template" do
        expect(response).to render_template(:signed_out)
      end
    end
  end
end

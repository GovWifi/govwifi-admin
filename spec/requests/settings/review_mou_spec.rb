describe "GET /settings/review_mou", type: :request do
  let(:user) { create(:user, :with_organisation) }
  let(:organisation) { user.organisations.first }

  before do
    https!
    sign_in_user(user)
  end

  context "when the organisation has signed an MOU" do
    before do
      create(:mou, organisation:, version: Mou.latest_known_version)
    end

    it "renders the review_mou template" do
      get review_mou_settings_path
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:review_mou)
    end
  end

  context "when the organisation has no MOU" do
    it "redirects to settings_path" do
      get review_mou_settings_path
      expect(response).to redirect_to(settings_path)
    end
  end
end

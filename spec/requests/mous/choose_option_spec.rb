describe "POST /mous/choose_option", type: :request do
  let(:user) { create(:user, :with_organisation) }
  before do
    https!
    sign_in_user(user)
  end
  describe "choose to sign the MOU directly" do
    it "redirects to the sign MOU page" do
      post choose_option_mous_path, params: { chosen_action: "sign_mou" }
      expect(response).to redirect_to(new_mou_path)
    end
  end
  describe "choose to nominate a user" do
    it "redirects to the nominate MOU page" do
      post choose_option_mous_path, params: { chosen_action: "nominate_user" }
      expect(response).to redirect_to(new_nomination_path)
    end
  end
  describe "choose an unknown option" do
    it "rerenders to the choose MOU page" do
      post choose_option_mous_path, params: { chosen_action: "invalid" }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response).to render_template(:show_options)
    end
  end
end

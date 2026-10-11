describe "GET /account_health/:organisation_id/:issue", type: :request do
  let(:user) { create(:user, :with_organisation) }
  let(:organisation) { create(:organisation) }

  before { https! }

  context "when signed in as a member of the organisation" do
    before do
      create(:membership, :confirmed, user:, organisation:)
      sign_in_user(user)
    end

    it "switches to the organisation and redirects to the MoU page" do
      get account_health_link_path(organisation_id: organisation.id, issue: "no_signed_mou")

      expect(response).to redirect_to("/mous/show_options")
      expect(session[:organisation_id]).to eq(organisation.id)
    end

    it "redirects fewer than two administrators to the Team members page" do
      get account_health_link_path(organisation_id: organisation.id, issue: "fewer_than_two_administrators")

      expect(response).to redirect_to("/memberships")
    end

    it "redirects inactive administrators to the Team members page" do
      get account_health_link_path(organisation_id: organisation.id, issue: "inactive_administrator")

      expect(response).to redirect_to("/memberships")
    end

    it "redirects missing location details to the Locations page" do
      get account_health_link_path(organisation_id: organisation.id, issue: "missing_location_details")

      expect(response).to redirect_to("/ips")
    end
  end

  context "when signed in but not a member of the organisation" do
    before { sign_in_user(user) }

    it "does not switch organisation" do
      get account_health_link_path(organisation_id: organisation.id, issue: "no_signed_mou")

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("You are not a member of the organisation in that link.")
      expect(session[:organisation_id]).to be_nil
    end
  end

  context "when not signed in" do
    it "asks the user to sign in first" do
      get account_health_link_path(organisation_id: organisation.id, issue: "no_signed_mou")

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end

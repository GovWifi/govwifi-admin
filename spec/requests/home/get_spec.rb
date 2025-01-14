describe "GET /home", type: :request do
  let(:organisation) do
    org = create(:organisation, :with_locations)
    create(:ip, location: org.locations.first)
    org
  end
  let(:user) { create(:user, :confirm_all_memberships, :with_2fa, organisations: [organisation]) }
  let(:super_admin) { create(:user, :super_admin) }

  before do
    super_admin
    https!
  end

  context "when the user is a super admin" do
    before do
      sign_in_user super_admin
    end

    it "redirects to the super admin organisation page" do
      get root_path

      expect(response).to redirect_to("/super_admin/organisations")
    end
  end

  context "when the user is not a super admin" do
    context "with a confirmed organisation" do
      before do
        sign_in_user user
      end

      it "redirects to the locations path" do
        get root_path

        expect(response).to redirect_to ips_path
      end
    end
  end
end

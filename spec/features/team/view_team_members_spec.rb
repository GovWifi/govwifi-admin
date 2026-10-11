describe "View team members of my organisation", type: :feature do
  context "when logged out" do
    before { visit memberships_path }

    it_behaves_like "not signed in"
  end

  context "when logged in" do
    let(:organisation) { create(:organisation) }
    let(:user) { create(:user, :confirm_all_memberships, email: "me@example.gov.uk", name: "bob", organisations: [organisation]) }

    before do
      ENV["LONDON_RADIUS_IPS"] = "1.1.1.1,2.2.2.2"
      ENV["DUBLIN_RADIUS_IPS"] = "1.1.1.1,2.2.2.2"
    end

    context "when there is only one user in an organisation" do
      before do
        sign_in_user user
        visit memberships_path
      end

      it "shows the users email" do
        expect(page).to have_content(user.email)
      end

      it "shows alert to remind admins there must be minimum of two administrators for each organisation" do
        expect(page).to have_content("There must be a minimum of 2 administrators for each organisation.")
      end
    end

    context "when there are many users in my organisation" do
      let!(:user_1) { create(:user, name: "bill", email: "bill@example.gov.uk", organisations: [organisation]) }
      let!(:user_2) { create(:user, name: "amada", organisations: [organisation]) }
      let!(:user_3) { create(:user, name: "zara", organisations: [organisation]) }

      before do
        sign_in_user user
        visit memberships_path
      end

      it "renders all team members within my organisation in alphabetical order" do
        expect(page.body).to match(/#{user_2.name}.*#{user_1.email}.*#{user.name}.*#{user_3.name}/m)
      end
    end

    context "when there are users outside of my organisation" do
      before do
        other_organisation = create(:organisation, name: "Gov Org 2")
        create(:user, email: "stranger@example.gov.uk", organisations: [other_organisation])
        sign_in_user user
        visit memberships_path
      end

      it "does not include users from other organisations" do
        expect(page).not_to have_content("stranger@example.gov.uk")
      end
    end
  end
end

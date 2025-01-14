require "rack_session_access/capybara"

describe "Switching organisations", type: :feature do
  before do
    sign_in_user user
  end

  describe "Unconfirmed memberships" do
    let(:confirmed_org) { create(:organisation) }
    let(:unconfirmed_org) { create(:organisation) }
    let(:user) { create(:user) }
    before :each do
      create(:membership, :confirmed, organisation: confirmed_org, user:)
      create(:membership, :unconfirmed, organisation: unconfirmed_org, user:)
      create(:organisation)
      visit root_path
      click_on "Switch organisation"
    end
    it "displays a button for the confirmed organisation membership" do
      expect(page).to have_button(confirmed_org.name)
    end
    it "does not display a button for the unconfirmed organisation membership" do
      expect(page).to_not have_button(unconfirmed_org.name)
    end
  end

  context "with two confirmed organisations" do
    let(:user) { create(:user) }
    let(:organisation_1) { create(:organisation) }
    let(:organisation_2) { create(:organisation) }
    before do
      create(:membership, :confirmed, organisation: organisation_1, user:)
      create(:membership, :confirmed, organisation: organisation_2, user:)
    end
    context "when switching organisations" do
      before do
        visit root_path
        click_on "Switch organisation"
      end

      it "does not display the sidenav" do
        expect(page).not_to have_selector ".leftnav"
      end

      it "displays a button for organisation one" do
        expect(page).to have_button(organisation_1.name)
      end

      it "displays a button for organisation two" do
        expect(page).to have_button(organisation_2.name)
      end

      it "changes the organisation the user is viewing" do
        click_on organisation_2.name
        within ".subnav" do
          expect(page).to have_content(organisation_2.name)
        end
      end
    end

    context "when the session is updated manually" do
      context "when the user doesn't belong to the organisation in the session" do
        let(:non_member_organisation) { create(:organisation) }
        before do
          page.set_rack_session(organisation_id: non_member_organisation.id)
          visit root_path
        end

        it "dissallows switching to that organisation" do
          expect(page).not_to have_content(non_member_organisation.name)
        end
      end

      context "when the user belongs to the organisation in the session" do
        before do
          page.set_rack_session(organisation_id: organisation_2.id)
          visit root_path
        end

        it "allows switching to that organisation" do
          expect(page).to have_content(organisation_2.name)
        end
      end
    end
  end
end

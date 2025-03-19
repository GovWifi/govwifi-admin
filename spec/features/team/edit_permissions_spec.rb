describe "Edit user permissions", type: :feature do
  let(:organisation) { create(:organisation) }
  let(:user) { create(:user, :confirm_all_memberships, organisations: [organisation]) }
  let(:invited_user_other_org) { User.find_by(email: "invited_other_org@gov.uk") }
  let(:invited_user_same_org) { User.find_by(email: "invited_same_org@gov.uk") }

  before do
    create(:user, :with_organisation, email: "invited_other_org@gov.uk")
    create(:user, email: "invited_same_org@gov.uk", organisations: [organisation])
    sign_in_user user
  end

  context "without the .can_manage_team permission" do
    before do
      user.membership_for(organisation).update!(can_manage_team: false)
    end

    it "does not show the edit team member link" do
      visit memberships_path
      expect(page).not_to have_link("Edit")
    end

    it "prevents visiting the edit permissions page directly" do
      membership = invited_user_same_org.membership_for(organisation)
      expect {
        visit edit_membership_path(membership)
      }.to raise_error(ActionController::RoutingError)
    end
  end

  context "with the .can_manage_team permission" do
    context "when the user belongs to my organisation" do
      let!(:second_user) { create(:user, organisations: [organisation]) }

      before do
        visit memberships_path
      end

      context "when there are are two or less admin users for an organisation" do
        context "the user wants to edit permissions for an admin who has yet to confirm" do
          before do
            visit edit_membership_path(invited_user_same_org.membership_for(organisation))
            choose "View only"
            click_on "Save"
          end

          it "asks for confirmation" do
            expect(page).to have_content("Are you sure you want to change permissions for #{invited_user_same_org.name}?\nYes, change permissions\nCancel")
          end

          it "choice to be view only" do
            expect(find("#membership-permission-level-view-only-field")).to be_checked
          end
        end

        context "the user wants to edit permissions for an admin who has confirmed" do
          before do
            second_user.membership_for(organisation).confirm!
            visit edit_membership_path(second_user.membership_for(organisation))
            choose "View only"
            click_on "Save"
          end

          it "shows the flash alert" do
            expect(page).to have_content("There is a problem\nYou must add another administrator before you can change permissions for #{second_user.name}.")
          end
        end
      end

      context "when there are more than two admin users for an organisation" do
        before do
          user.membership_for(organisation).confirm!
          second_user.membership_for(organisation).confirm!
          invited_user_same_org.membership_for(organisation).confirm!
          visit edit_membership_path(second_user.membership_for(organisation))
          choose "View only"
          click_on "Save"
        end

        it "asks for confirmation" do
          expect(page).to have_content("Are you sure you want to change permissions for #{second_user.name}?")
        end

        it "displays a link to cancel" do
          expect(page).to have_link("Cancel")
        end

        it "will take the user to the memberships page when they click 'Cancel'" do
          click_on "Cancel"
          expect(page).to have_current_path(memberships_path)
        end

        it "still has the save button when already clicked" do
          expect(page).to have_button("Save")
        end

        context "the user has confirmed changes" do
          before do
            click_on "Yes, change permissions"
          end

          it "correctly sets the manage team permissions" do
            expect(second_user.membership_for(organisation).can_manage_team?).to eq(false)
          end

          it "correctly sets the manage locations permissions" do
            expect(second_user.membership_for(organisation).can_manage_locations?).to eq(false)
          end

          it "sets the correct success message" do
            expect(page).to have_content("Permissions updated")
          end

          it 'redirects to "after permission updated" team members page for analytics' do
            expect(page).to have_current_path("/memberships")
          end
        end
      end
    end

    context "when the user does not belong to my organisation" do
      it "restricts editing to only users in my organisation" do
        membership = invited_user_other_org.memberships.first
        expect {
          visit edit_membership_path(membership)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end

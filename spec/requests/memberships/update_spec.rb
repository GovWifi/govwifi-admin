describe "PATCH /memberships/:id", type: :request do
  let(:new_permission_level) { "view_only" }
  let(:organisation) { create(:organisation) }
  let(:user) { create(:user, organisations: [organisation]) }
  let(:second_user) { create(:user, organisations: [organisation]) }
  let(:third_user) { create(:user, organisations: [organisation]) }

  before do
    user.membership_for(organisation).update!(can_manage_team: true)
    second_user.membership_for(organisation).update!(can_manage_team: true)
    user.membership_for(organisation).confirm!
    second_user.membership_for(organisation).confirm!
    https!
    sign_in_user(user)
  end

  context "when checks for validate preserve admin permissions" do
    let(:membership) { second_user.memberships.first }

    context "returns true" do
      it "doesn't allow update and redirects" do
        membership.confirm!
        expect {
          patch membership_path(membership), params: { permission_level: new_permission_level }
        }.to raise_error(StandardError, /Changing permissions would result in too few administrators/)
      end
    end

    context "returns false" do
      before do
        third_user.membership_for(organisation).update!(can_manage_team: true)
        third_user.membership_for(organisation).confirm!
      end

      it "updates the membership" do
        patch membership_path(membership), params: { permission_level: new_permission_level }
        expect(response).to redirect_to(memberships_path)
        expect(flash[:notice]).to eq("Permissions updated")

        membership.reload
        expect(membership.permission_level).not_to eq("administrator")
        expect(membership.can_manage_team).to be false
        expect(membership.can_manage_locations).to be false
      end
    end
  end
end

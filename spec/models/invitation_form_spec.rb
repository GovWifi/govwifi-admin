describe InvitationForm do
  include EmailHelpers
  let(:email) { "tom@gov.uk" }
  let(:permission_level) { Membership::Permissions::VIEW_ONLY }
  let(:organisation) { create(:organisation) }
  let(:form) { InvitationForm.new(email:, permission_level:, inviter:, organisation:) }
  let(:inviter) { create(:user, organisations: [organisation]) }
  let(:user) { User.find_by_email(email) }
  context "The user exists" do
    before do
      create(:user, email:)
      form.save!
    end
    it "creates a new membership with the correct permission level" do
      membership = user.membership_for(organisation)
      expect(membership).to_not be_nil
      expect(membership.permission_level).to eq(permission_level)
    end
    it "sends an invitation email" do
      it_sent_a_cross_organisational_invitation_email
    end
  end
  context "The user doesn't exist" do
    before do
      form.save!
    end
    it "creates a new unconfirmed user" do
      expect(user).to_not be_nil
      expect(user).to_not be_confirmed
    end
    it "creates a new membership with the correct permission level" do
      membership = user.membership_for(organisation)
      expect(membership).to_not be_nil
      expect(membership.permission_level).to eq(permission_level)
    end
    it "sends an invitation email" do
      it_sent_a_cross_organisational_invitation_email
      it_sent_an_email_to user.email
      it_sent_one_email
    end
  end
  context "The user is already a member of the organisation" do
    before do
      create(:user, email:, organisations: [organisation])
    end
    it "does not validate" do
      form.validate
      expect(form.errors[:email]).to include("This email address is already associated with an administrator account")
    end
  end
  context "an invalid email address" do
    let(:email) { "invalid" }
    before do
      create(:user)
    end
    it "does not validate" do
      form.validate
      expect(form.errors[:email]).to include("Invalid Email address")
    end
  end
  context "an invalid permission level" do
    let(:permission_level) { "invalid" }
    before do
      create(:user)
    end
    it "does not validate" do
      form.validate
      expect(form.errors[:permission_level]).to include("Invalid permission")
    end
  end
  context "the inviter does not have the correct permission level" do
    let(:inviter) do
      create(:user).tap do |u|
        u.memberships.create(organisation:, permission_level: Membership::Permissions::VIEW_ONLY)
      end
    end
    it "does not validate" do
      expect { form }.to raise_error(InvitationForm::InvalidPermissionsError, /Invalid permission/)
    end
  end
end

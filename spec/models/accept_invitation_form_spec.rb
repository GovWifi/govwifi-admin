describe AcceptInvitationForm do
  let(:name) { "Tom" }
  let(:password) { "S3Cret!123" }
  let(:email) { "tom@gov.uk" }
  let(:organisation) { create(:organisation) }
  let(:membership) { user.membership_for(organisation) }
  let(:invitation_token) { membership.invitation_token }
  let(:form) { AcceptInvitationForm.new(name:, password:, invitation_token:) }
  context "The user has been confirmed" do
    let(:user) { create(:user) }
    before do
      create(:membership, :unconfirmed, user:, organisation:)
    end
    it "does not change the name" do
      expect {
        form.save!
        user.reload
      }.not_to change(user, :name)
    end
    it "does not change the password" do
      expect {
        form.save!
        user.reload
      }.not_to change(user, :encrypted_password)
    end
    it "confirms the membership" do
      expect {
        form.save!
        membership.reload
      }.to change(membership, :confirmed?).from(false).to(true)
    end
    it "is valid regardless of the presence of the name and the password" do
      expect(AcceptInvitationForm.new(invitation_token:).save!).to be true
    end
  end
  context "The user has not been confirmed" do
    let(:user) { create(:user, :unconfirmed) }
    before do
      create(:membership, :unconfirmed, user:, organisation:)
    end
    it "does not change the name" do
      expect {
        form.save!
        user.reload
      }.to change(user, :name).to(name)
    end
    it "does not change the password" do
      expect {
        form.save!
        user.reload
      }.to change {
        user.valid_password?(password)
      }.from(false).to(true)
    end
    it "confirms the membership" do
      expect {
        form.save!
        membership.reload
      }.to change(membership, :confirmed?).from(false).to(true)
    end
    it "confirms the user" do
      expect {
        form.save!
        user.reload
      }.to change(user, :confirmed?).from(false).to(true)
    end
    it "is valid" do
      expect(form.save!).to be true
    end
    describe "empty name" do
      let(:name) { "" }
      it "is invalid" do
        expect(form.save!).to be false
        expect(form.errors[:name]).to eq ["Name can't be blank"]
      end
    end
    describe "password too short" do
      let(:password) { "abc" }
      it "is invalid" do
        expect(form.save!).to be false
        expect(form.errors[:password]).to eq ["Password is too short (minimum is 6 characters)"]
      end
    end
    describe "password too long" do
      let(:password) { "a" * 100 }
      it "is invalid" do
        expect(form.save!).to be false
        expect(form.errors[:password]).to eq ["Password is too long (maximum is 80 characters)"]
      end
    end
    describe "password is weak" do
      let(:password) { "a" * 10 }
      it "is invalid" do
        expect(form.save!).to be false
        expect(form.errors[:password]).to eq ["Password is not strong enough. Choose a different password."]
      end
    end
    describe "The invitation token is invalid" do
      let(:invitation_token) { "invalid" }
      it "is invalid" do
        expect { form.save! }.to raise_error AcceptInvitationForm::InvalidTokenError, /Invalid invitation token/
      end
    end
  end
end

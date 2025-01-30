describe UserMembershipForm do
  let(:name) { "tom" }
  let(:password) { "S3Cret!123" }
  let(:service_email) { "tom@gov.uk" }
  let(:organisation_name) { "Gov Org 1" }
  let(:confirmation_token) { user.confirmation_token }
  let(:user) { FactoryBot.create(:user, :unconfirmed, name: "harry", email: "harry@gov.uk") }
  let(:form) { UserMembershipForm.new(name:, password:, service_email:, organisation_name:, confirmation_token:) }

  describe "Updating attributes" do
    it "updates the name" do
      form.save!
      expect(user.reload.name).to eq("tom")
    end
    it "updates the password" do
      form.save!
      expect(user.reload.valid_password?(password)).to eq(true)
    end
    it "updates the users organisation name" do
      form.save!
      expect(user.reload.organisations.first.name).to eq("Gov Org 1")
    end
    it "updates the users organisation email address" do
      form.save!
      expect(user.reload.organisations.first.service_email).to eq("tom@gov.uk")
    end
    it "confirms the user" do
      expect { form.save! }.to change { user.reload.confirmed? }.from(false).to(true)
    end
    it "adds an organisation" do
      expect { form.save! }.to change { user.reload.organisations.count }.from(0).to(1)
    end
    it "confirms the membership" do
      form.save!
      expect(user.reload.memberships.last.confirmed?).to be true
    end
    it "returns true" do
      expect(form.save!).to be true
    end
  end
  describe "failing validations" do
    describe "invalid token" do
      let(:confirmation_token) { "invalid" }
      it "raises an error" do
        expect { form }.to raise_error(UserMembershipForm::InvalidTokenError, /Invalid confirmation token/)
      end
    end
    describe "user already confirmed" do
      let(:user) { FactoryBot.create(:user, name: "harry", email: "harry@gov.uk") }
      it "raises an error" do
        expect { form }.to raise_error(UserMembershipForm::AlreadyConfirmedError, /already confirmed/)
      end
    end
    describe "blank name and blank password" do
      let(:name) { "" }
      let(:password) { "" }
      it "copies the validations" do
        form.save!
        expect(form.errors.map(&:full_message)).to match_array(["Name can't be blank",
                                                                "Password can't be blank",
                                                                "Password is too short (minimum is 6 characters)"])
      end
      it "returns false" do
        expect(form.save!).to be false
      end
    end
    describe "blank service email and blank organisation" do
      let(:organisation_name) { "" }
      let(:service_email) { "" }
      it "copies the validations" do
        form.save!
        expect(form.errors.map(&:full_message)).to match_array(["Name can't be blank",
                                                                "Service email must be in the correct format, like name@example.com",
                                                                "Name isn't in the organisations allow list"])
      end
    end
  end
end

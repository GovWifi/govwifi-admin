describe User do
  let(:organisation) { create(:organisation) }

  describe "validation" do
    let(:user) { create(:user) }
    let(:pw) { "this is 333 a strong !!! password" }

    it "has a valid factory user" do
      expect(user).to be_valid
    end

    # rubocop:disable Rails/SaveBang
    ["password123", "my password", "pa55w0rd"].each do |weak_pass|
      it "does not accept a weak password (#{weak_pass})" do
        user.update(password: weak_pass)

        expect(user).not_to be_valid
      end

      it "accepts a strong password" do
        user.update(password: pw)

        expect(user).to be_valid
      end

      it "checks for a password confirmation field" do
        user.update(password: pw, password_confirmation: pw.reverse)

        expect(user).not_to be_valid
      end
    end
    # rubocop:enable Rails/SaveBang
  end

  context "when ordering a collection of users" do
    let(:user_1) { create(:user, name: "Aardvark") }
    let(:user_2) { create(:user, name: "Zed") }
    let(:user_3) { create(:user, name: "Dave", email: "batman@batcave.com") }

    it "orders the users by name and email" do
      expect(User.all.order_by_name_and_email).to eq([user_1, user_3, user_2])
    end
  end

  context "when checking if a membership is pending" do
    subject(:user) { create(:user, organisations: [organisation]) }

    let(:organisation) { create(:organisation) }

    it "returns true if the membership is pending" do
      expect(user.pending_membership_for?(organisation:)).to eq(true)
    end
  end

  describe "need_two_factor_authentication?" do
    subject(:user) { create(:user, organisations: [organisation]) }

    let(:warden) { instance_double(Warden::Proxy, user: subject) }
    let(:request) { instance_double(ActionDispatch::Request, env: { "warden" => warden }) }
    let(:organisation) { create(:organisation) }

    before do
      allow(warden).to receive(:session).with(:user) { Hash[TwoFactorAuthentication::NEED_AUTHENTICATION => nil] }
    end

    context "with a normal admin user" do
      it "is true" do
        expect(user.need_two_factor_authentication?(request)).to be true
      end
    end

    context "when bypassed with an environment variable" do
      before { allow(ENV).to receive(:key?).with("BYPASS_2FA").and_return(true) }

      it "is false" do
        expect(user.need_two_factor_authentication?(request)).to be false
      end
    end
  end

  describe "can_manage_other_user_for_org?" do
    let(:organisation) { create(:organisation) }

    let(:superadmin) { create(:user, :super_admin) }
    let(:admin) { create(:user, organisations: [organisation]) }
    let(:user) { create(:user, organisations: [organisation]) }
    let(:colleague) { create(:user, organisations: [organisation]) }

    context "when the operator is a super admin" do
      it "returns true" do
        expect(superadmin.can_manage_other_user_for_org?(user, organisation))
          .to be true
      end
    end

    context "when the operator is not entitled to manage the team" do
      before do
        colleague.membership_for(organisation).update!(can_manage_team: false)
      end

      it "returns false" do
        expect(colleague.can_manage_other_user_for_org?(user, organisation))
          .to be false
      end
    end

    context "when the operator can manage the team" do
      it "returns true" do
        expect(admin.can_manage_other_user_for_org?(user, organisation))
          .to be true
      end
    end

    context "when the user is not part of the same org" do
      it "returns false" do
        expect(admin.can_manage_other_user_for_org?(create(:user, :with_organisation), organisation))
          .to be false
      end
    end

    context "when the operator is not part of the same org" do
      it "returns false" do
        expect(create(:user, :with_organisation).can_manage_other_user_for_org?(user, organisation))
          .to be false
      end
    end
  end

  describe "reset_2fa!" do
    let(:user) { create(:user, :with_2fa) }

    before do
      user.reset_2fa!
    end

    it "resets the two factor auth" do
      expect(user).not_to be_totp_enabled
    end
  end

  describe "#search" do
    let(:name) { "bob" }
    let(:email) { "admin.user@govwifi.org" }
    before do
      create(:user, name:, email:)
    end

    context "with name as search term" do
      it "finds an admin user" do
        expect(User.search("BoB").name).to eq(name)
      end
    end

    context "with email as search term" do
      it "finds an admin user" do
        expect(User.search("aDmIn.uSEr@govWIFI.org").email).to eq(email)
      end
    end

    context "with only partial search term" do
      before do
        create(:user, email: "newadmin.user@govwifi.org")
        create(:user, name: "adminname")
      end

      it "first finds an admin user by similar name" do
        found_user = User.search("min")
        expect(found_user).not_to be_nil
        expect(found_user.name).to eq("adminname")
      end

      it "then finds an admin user by similar email" do
        found_user = User.search("newad")
        expect(found_user).not_to be_nil
        expect(found_user.email).to eq("newadmin.user@govwifi.org")
      end
    end
  end

  describe "#admin_usage_csv" do
    it "has the correct headers" do
      expect(User.admin_usage_csv).to eq("email,admin name,current sign in date,last sign in date,number of sign ins,organisation name\n")
    end
    it "returns the correct rows" do
      current_sign_in_at = Time.zone.local(2022, 1, 1)
      last_sign_in_at = Time.zone.local(2022, 2, 2)
      email = "test@gov.uk"
      organisation_name = "Gov Org 1"
      name = "Test User"
      sign_in_count = 2

      create(:user,
             name:,
             current_sign_in_at:,
             last_sign_in_at:,
             email:,
             sign_in_count:,
             organisations: [create(:organisation, name: organisation_name)])

      expect(User.admin_usage_csv)
        .to include("#{email},#{name},#{current_sign_in_at},#{last_sign_in_at},#{sign_in_count},#{organisation_name}\n")
    end
  end

  describe "#confirmed_member_of?" do
    let(:user) { create(:user) }
    let(:organisation) { create(:organisation) }

    it "is a confirmed member" do
      create(:membership, :confirmed, user:, organisation:)
      expect(user.reload.confirmed_member_of?(organisation)).to be true
    end
    it "is not confirmed member" do
      create(:membership, :unconfirmed, user:, organisation:)
      expect(user.reload.confirmed_member_of?(organisation)).to be false
    end
  end
end

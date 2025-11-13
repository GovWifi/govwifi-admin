describe UseCases::ResetSmokeTestUsers do
  subject { UseCases::ResetSmokeTestUsers }
  describe "reset smoke test users" do
    let(:existing_user_email) { "user@gov.uk" }
    let(:missing_user_email)  { "missing_user@gov.uk" }
    let(:old_password)        { "Oldpassword1!" }
    let(:new_password)        { "Newpassword1!" }
    let(:failed_attempts) { 3 }
    let(:second_factor_attempts) { 3 }
    let(:site_ips) { ["1.1.1.1", "2.2.2.2", "3.3.3.3"] }
    let(:session_ips) { ["1.2.3.4", "5,6,7,8", "4,3,2,1"] }
    let(:users) { { existing_user_email => new_password } }
    let(:reset_service) { UseCases::ResetSmokeTestUsers.new(users, site_ips) }

    def create_user(email:, password:)
      User.create!(
        name: "Test User",
        email: email,
        password: password,
        password_confirmation: password,
        confirmed_at: Time.current,
        failed_attempts: failed_attempts,
        second_factor_attempts_count: failed_attempts,
      )
    end

    def create_sessions(ips)
      ips.length.times do |i|
        Session.create!(
          start: (Time.zone.now - (i + 5).day).to_s,
          success: 1,
          username: "gwstud",
          siteIP: ips[i],
        )
      end
    end

    context "when all users exist" do
      it "resets passwords successfully" do
        create_user(email: existing_user_email, password: old_password)

        result = reset_service.reset_user

        expect(result).to eq([
          { email: existing_user_email, status: :success },
        ])

        user = User.find_by(email: existing_user_email)
        expect(user.valid_password?(new_password)).to be true
        expect(user.failed_attempts).to eq 0
        expect(user.second_factor_attempts_count).to eq 0
      end
    end

    context "when some users do not exist" do
      it "returns not found for missing users" do
        create_user(email: existing_user_email, password: old_password)

        users = {
          existing_user_email => new_password, missing_user_email => new_password
        }

        result = UseCases::ResetSmokeTestUsers.new(users, site_ips).reset_user

        expect(result).to contain_exactly(
          { email: existing_user_email, status: :success },
          { email: missing_user_email,  status: :not_found },
        )
      end
    end

    context "When site ids exist for the govwifi smoke test user" do
      it "Remove  only govwifi test site id's for the govwifi smoke test users" do
        create_sessions(site_ips + session_ips)

        result = reset_service.clear_session_ips
        expect(result).to contain_exactly(
          { status: :success, rows_deleted: 1 },
          { status: :success, rows_deleted: 1 },
          { status: :success, rows_deleted: 1 },
        )
      end
    end
    context "When site ids not exist for the govwifi smoke test user" do
      it "don't remove site id's for the govwifi smoke test users" do
        create_sessions(session_ips)

        result = reset_service.clear_session_ips

        expect(result).to contain_exactly(
          { status: :not_found },
          { status: :not_found },
          { status: :not_found },
        )
      end
    end
    context "When no site ids are provided for the govwifi smoke test user" do
      it "Return a not found message" do
        result = UseCases::ResetSmokeTestUsers.new(users, []).clear_session_ips

        expect(result).to eq({ status: :error, message: "No site Ips provided" })
      end
    end
  end
end

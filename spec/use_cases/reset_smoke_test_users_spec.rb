describe UseCases::ResetSmokeTestUsers do
  subject { UseCases::ResetSmokeTestUsers }
  describe "reset smoke test users" do
    let(:existing_user_email) { "user@gov.uk" }
    let(:missing_user_email)  { "missing_user@gov.uk" }
    let(:old_password)        { "Oldpassword1!" }
    let(:new_password)        { "Newpassword1!" }

    def create_user(email:, password:)
      User.create!(
        name: "Test User",
        email: email,
        password: password,
        password_confirmation: password,
        confirmed_at: Time.current,
      )
    end

    context "when all users exist" do
      it "resets passwords successfully" do
        create_user(email: existing_user_email, password: old_password)

        users = { existing_user_email => new_password }
        result = described_class.new(users).execute

        expect(result).to eq([
          { email: existing_user_email, status: :success },
        ])

        user = User.find_by(email: existing_user_email)
        expect(user.valid_password?(new_password)).to be true
      end
    end

    context "when some users do not exist" do
      it "returns not found for missing users" do
        create_user(email: existing_user_email, password: old_password)

        users = {
          existing_user_email => new_password, missing_user_email => new_password
        }

        result = described_class.new(users).execute

        expect(result).to contain_exactly(
          { email: existing_user_email, status: :success },
          { email: missing_user_email,  status: :not_found },
        )
      end
    end
  end
end

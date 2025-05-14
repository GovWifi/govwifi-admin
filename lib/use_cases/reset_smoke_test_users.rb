module UseCases
  class ResetSmokeTestUsers
    def initialize(user_credentials)
      @user_credentials = user_credentials
    end

    def execute
      @user_credentials.map do |email, password|
        user = User.find_by(email: email)
        if user.nil?
          { email: email, status: :not_found }
        else
          begin
            user.update!(
              password: password,
              password_confirmation: password,
              confirmed_at: user.created_at,
            )
            { email: email, status: :success }
          rescue StandardError => e
            { email: email, status: :error, message: e.message }
          end
        end
      end
    end
  end
end

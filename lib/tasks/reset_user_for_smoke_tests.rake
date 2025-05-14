namespace :smoke_test do
  desc "Reset smoke test users to the passwords defined in environment variables"

  task reset_users: :environment do
    users = {
      ENV["GW_USER"] => ENV["GW_PASS"],
      ENV["GW_SUPER_ADMIN_USER"] => ENV["GW_SUPER_ADMIN_PASS"],
    }
    puts "Running password reset in: #{Rails.env}"
    users.each do |email, password|
      user = User.find_by(email: email)

      begin
        user.update!(
          password: password,
          password_confirmation: password,
          confirmed_at: user.created_at,
        )
        puts "Reset password for #{email}"
      rescue StandardError => e
        puts "Failed to reset password for #{email}: #{e.message}"
      end
    end
  end
end

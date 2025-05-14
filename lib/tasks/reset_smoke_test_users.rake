namespace :reset do
  desc "Reset smoke test users to the passwords stored in AWS"
  task smoke_test_users: :environment do
    users = {
      ENV["GW_USER"] => ENV["GW_PASS"],
      ENV["GW_SUPER_ADMIN_USER"] => ENV["GW_SUPER_ADMIN_PASS"],
    }

    puts "Running password reset in: #{Rails.env}"

    results = UseCases::ResetSmokeTestUsers.new(users).execute

    results.each do |result|
      case result[:status]
      when :success
        puts "Reset password for #{result[:email]}"
      when :not_found
        puts "User not found for #{result[:email]}"
      when :error
        puts "Failed to reset password for #{result[:email]}: #{result[:message]}"
      end
    end
  end
end

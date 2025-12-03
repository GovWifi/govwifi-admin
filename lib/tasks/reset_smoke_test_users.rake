namespace :reset do
  desc "Reset smoke test users to the passwords stored in AWS"
  task smoke_test_users: :environment do
    users = {
      ENV["GW_USER"] => ENV["GW_PASS"],
      ENV["GW_SUPER_ADMIN_USER"] => ENV["GW_SUPER_ADMIN_PASS"],
    }
    site_ips = ENV["SMOKE_TEST_IPS"].split(",")

    puts "Running password reset in: #{Rails.env}"
    smoke_test_reset = UseCases::ResetSmokeTestUsers.new(users, site_ips)
    user_results = smoke_test_reset.reset_user

    user_results.each do |result|
      case result[:status]
      when :success
        puts "Reset password for #{result[:email]}"
      when :not_found
        puts "User not found for #{result[:email]}"
      when :error
        puts "Failed to reset password for #{result[:email]}: #{result[:message]}"
      end
    end

    session_results = smoke_test_reset.clear_session_ips

    session_results.each do |result|
      case result[:status]
      when :success
        puts "#{result[:rows_deleted]} site Ip's removed successfully"
      when :not_found
        puts "No site Ips found to remove"
      when :error
        puts "Failed to to remove ips due to #{result[:message]}"
      end
    end
  end
end

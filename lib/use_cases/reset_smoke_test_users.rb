module UseCases
  class ResetSmokeTestUsers
    def initialize(user_credentials, site_ips)
      @user_credentials = user_credentials
      @site_ips = site_ips
      @logger = Logger.new($stdout)
    end

    def clear_session_ips
      @logger.info("Site Ips to be removed: #{@site_ips}")
      if @site_ips.blank? || @site_ips.empty?
        @logger.error("No smoke test site IPs provided, ensure env SMOKE_TEST_IPS is set, skipping session deletion")
        return { status: :error, message: "No site Ips provided" }
      end
      @site_ips.map do |site_ip|
        @logger.info("Processing smoke test site IP: #{site_ip}")
        sessions = Session.where(siteIp: site_ip)
        @logger.info("Found #{sessions.count} sessions to delete for smoke test site IP  #{site_ip}")
        if sessions.nil? || sessions.count.zero?
          { status: :not_found }
        else
          begin
            total = Session.where(siteIp: site_ip).delete_all
            @logger.info("Finished, #{total} row(s) delated")
            { status: :success, rows_deleted: total }
          rescue StandardError => e
            @logger.error("Error deleting sessions for site IP #{site_ip}: #{e.message}")
            { status: :error, message: e.message }
          end
        end
      end
    end

    def reset_user
      @user_credentials.map do |email, password|
        user = User.find_by(email: email)
        @logger.info("Starting smoke test user reset for #{email}")
        if user.nil?
          { email: email, status: :not_found }
        else
          @logger.info("user failed attempts before reset: #{user.failed_attempts}, 2FA attempts: #{user.second_factor_attempts_count}")
          begin
            user.update!(
              password: password,
              password_confirmation: password,
              confirmed_at: user.created_at,
              failed_attempts: 0,
              second_factor_attempts_count: 0,
              locked_at: nil,
              unlock_token: nil,
            )
            @logger.info("user failed attempts after reset: #{user.failed_attempts}, 2FA attempts: #{user.second_factor_attempts_count}")
            { email: email, status: :success }
          rescue StandardError => e
            @logger.error("Error resetting smoke test user #{email}: #{e.message}")
            { email: email, status: :error, message: e.message }
          end
        end
      end
    end
  end
end

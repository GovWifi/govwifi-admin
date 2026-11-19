namespace :backup do
  desc "Backup Team Members"
  task team_members: :environment do
    UseCases::BackupTeamMembers.new(
      writer: Gateways::GoogleDrive.new(credentials: ENV["GOOGLE_SERVICE_ACCOUNT_BACKUP_CREDENTIALS"]),
    ).execute
  end
end

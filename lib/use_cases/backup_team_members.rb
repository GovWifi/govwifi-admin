require "csv"

module UseCases
  class BackupTeamMembers
    TEAM_MEMBER_COLUMNS = ["Org name", "Team member name", "Team member email", "Role", "Status"].freeze

    def initialize(writer:)
      @writer = writer
    end

    def execute
      csv = build_csv
      time = Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")

      @writer.write(
        file_name: "#{Deploy.env}-#{time}.csv",
        folder_name: "GovWifi Team Members Backup",
        upload_source: StringIO.new(csv),
        mime_type: "application/csv",
      )
    end

    def build_csv
      CSV.generate do |csv|
        csv << TEAM_MEMBER_COLUMNS
        ::Organisation.all
          .order(:name)
          .includes(:memberships, memberships: :user)
          .each do |o|
            o.memberships
              .select(&:user)
              .sort_by { |m| [m.user.name.to_s, m.user.email.to_s] }
              .each { |m| csv << team_member_row(o, m) }
          end
      end
    end

  private

    def team_member_row(organisation, membership)
      [
        organisation.display_name,
        membership.user.name.to_s.squish,
        membership.user.email.to_s.squish,
        role(membership),
        status(membership),
      ]
    end

    def role(membership)
      return "administrator" if membership.can_manage_team?

      return "location_manager" if membership.can_manage_locations?

      "view_only"
    end

    def status(membership)
      membership.confirmed? ? "confirmed" : "invited"
    end
  end
end

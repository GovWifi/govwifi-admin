module UseCases
  module AccountHealth
    # The account health rules: which organisations are affected by each one.
    class Checks
      RULES = %i[
        no_signed_mou
        missing_location_details
        fewer_than_two_administrators
        inactive_administrator
      ].freeze

      INACTIVE_AFTER = 365.days

      # Accepted by Location#validate_postcode_format but not a real place.
      PLACEHOLDER_VALUES = %w[unknown].freeze

      def initialize(organisations = ::Organisation.all)
        @organisations = organisations
        @organisation_ids = {}
      end

      def organisation_ids(rule)
        @organisation_ids[rule] ||= find_organisation_ids(rule).sort
      end

      # Locations with at least one IP address whose address and postcode are both blank or a placeholder.
      def incomplete_locations
        ::Location
          .where(organisation_id: @organisations.select(:id))
          .where(id: ::Ip.select(:location_id))
          .where("#{missing_sql('locations.address')} AND #{missing_sql('locations.postcode')}")
      end

      # Administrators who have accepted their invitation, by organisation ID.
      # Organisations with none are not included.
      def confirmed_administrator_counts
        @confirmed_administrator_counts ||= ::Membership
          .where(organisation_id: @organisations.select(:id), can_manage_team: true, can_manage_locations: true)
          .where.not(confirmed_at: nil)
          .group(:organisation_id)
          .count
      end

      # Administrators who have not signed in for over a year. Someone who has never signed in is
      # inactive a year after accepting their invitation.
      def inactive_administrators
        ::Membership
          .joins(:user)
          .where(organisation_id: @organisations.select(:id), can_manage_team: true, can_manage_locations: true)
          .where.not(confirmed_at: nil)
          .where("COALESCE(users.current_sign_in_at, users.last_sign_in_at, memberships.confirmed_at) < ?", INACTIVE_AFTER.ago)
      end

    private

      def find_organisation_ids(rule)
        case rule
        when :no_signed_mou
          @organisations.where.missing(:mous).pluck(:id)
        when :missing_location_details
          incomplete_locations.distinct.pluck(:organisation_id)
        when :fewer_than_two_administrators
          @organisations.pluck(:id).select { |id| confirmed_administrator_counts.fetch(id, 0) < 2 }
        when :inactive_administrator
          inactive_administrators.distinct.pluck(:organisation_id)
        else
          raise ArgumentError, "Unknown account health rule: #{rule}"
        end
      end

      def missing_sql(column)
        ActiveRecord::Base.sanitize_sql_array([
          "(TRIM(COALESCE(#{column}, '')) = '' OR LOWER(TRIM(#{column})) IN (?))",
          PLACEHOLDER_VALUES,
        ])
      end
    end
  end
end

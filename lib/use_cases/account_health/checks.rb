module UseCases
  module AccountHealth
    # The account health rules: which organisations are affected by each one.
    class Checks
      RULES = %i[
        no_signed_mou
        missing_location_details
      ].freeze

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

    private

      def find_organisation_ids(rule)
        case rule
        when :no_signed_mou
          @organisations.where.missing(:mous).pluck(:id)
        when :missing_location_details
          incomplete_locations.distinct.pluck(:organisation_id)
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

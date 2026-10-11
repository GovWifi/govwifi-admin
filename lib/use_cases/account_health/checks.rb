module UseCases
  module AccountHealth
    # The account health rules: which organisations are affected by each one.
    class Checks
      RULES = %i[
        no_signed_mou
      ].freeze

      def initialize(organisations = ::Organisation.all)
        @organisations = organisations
        @organisation_ids = {}
      end

      def organisation_ids(rule)
        @organisation_ids[rule] ||= find_organisation_ids(rule).sort
      end

    private

      def find_organisation_ids(rule)
        case rule
        when :no_signed_mou
          @organisations.where.missing(:mous).pluck(:id)
        else
          raise ArgumentError, "Unknown account health rule: #{rule}"
        end
      end
    end
  end
end

module UseCases
  module Organisation
    class ResignMou
      def initialize(organisation_id:)
        @organisation_id = organisation_id
      end

      def execute
        organisation.require_mou_resign!
      end

    private

      def organisation
        @organisation ||= ::Organisation.find(@organisation_id)
      end
    end
  end
end

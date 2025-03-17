module UseCases
  module Administrator
    class PublishOrganisationNames
      def publish
        names = ::Organisation.pluck(:name)
        Gateways::S3.new(**Gateways::S3::ORGANISATION_NAME_LIST).write(names.to_yaml)
      end
    end
  end
end

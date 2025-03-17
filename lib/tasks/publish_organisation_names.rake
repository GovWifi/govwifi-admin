desc "Publish organisation_names to S3"
task publish_organisation_names: :environment do
  UseCases::Administrator::PublishOrganisationNames.new.publish
end

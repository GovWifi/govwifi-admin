desc "Publish organisations with inactive admins to S3"
task publish_organisations_with_inactive_admins: :environment do
  UseCases::Administrator::PublishOrganisationsWithInactiveAdmins.new.publish
end

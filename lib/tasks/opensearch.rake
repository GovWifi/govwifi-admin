require "logger"
logger = Logger.new($stdout)

namespace :opensearch do
  desc "Publishing metrics to OpenSearch"
  task publish_metrics: :environment do
    logger.info("Fetching and uploading metrics ...")

    logger.info("Fetching data on organisation usage")
    Gateways::Opensearch.new("govwifi-metrics").write("organisation_usage_stats-#{Time.zone.today}", UseCases::OrganisationUsage.fetch_stats)

    logger.info("Fetching data on new organisations signing up")
    Gateways::Opensearch.new("govwifi-metrics").write("new_organisations-#{Time.zone.today}", UseCases::NewOrganisations.fetch_stats)

    logger.info("Fetching data on new locations being added")
    Gateways::Opensearch.new("govwifi-metrics").write("new_locations-#{Time.zone.today}", UseCases::NewLocations.fetch_stats)

    logger.info("Fetching data on new cba organisations being added")
    Gateways::Opensearch.new("govwifi-metrics").write("new_cba_organisations-#{Time.zone.today}", UseCases::NewCbaOrganisations.fetch_stats)

    logger.info("Done.")
  end
end

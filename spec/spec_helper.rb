if ENV["COVERAGE"]
  require "simplecov"
  require "simplecov-console"

  SimpleCov.start do
    add_filter "/spec/"      # ignore spec/ files from coverage
    add_filter "/config/"    # optional: ignore config files
    add_filter "/vendor/"    # optional: ignore vendor
  end

  SimpleCov.minimum_coverage 90
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Console,
  ])
end

require_relative "../lib/gateways/govuk_organisations_register_gateway"

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  Dir["./spec/features/support/*.rb"].sort.each { |f| require f }

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.before do
    FactoryBot.reload
    ActionMailer::Base.deliveries.clear

    stub_const("Gateways::GovukOrganisationsRegisterGateway::GOVERNMENT_ORGS", [
      "Gov Org 1",
      "Gov Org 2",
      "Gov Org 3",
      "Gov Org 4",
    ].freeze)

    stub_const("Gateways::GovukOrganisationsRegisterGateway::LOCAL_AUTHORITIES", [
      "Local Auth 1",
      "Local Auth 2",
      "Local Auth 3",
      "Local Auth 4",
    ].freeze)
  end

  config.around do |example|
    original_s3_aws_config = Rails.application.config.s3_aws_config
    Services.notify_gateway.reset
    Object.send(:remove_const, :NotifyTemplates) if Object.const_defined?(:NotifyTemplates)
    load "notify_templates.rb"
    begin
      example.run
    ensure
      Rails.application.config.s3_aws_config = original_s3_aws_config
    end
  end
end

require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "sprockets/railtie"

require "notifications/client"
# require "rails/test_unit/railtie"
# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module GovwifiAdmin
  class Application < Rails::Application
    config.exceptions_app = routes
    config.load_defaults 7.0
    config.action_view.form_with_generates_remote_forms = false
    config.autoloader = :zeitwerk
    config.active_support.to_time_preserves_timezone = :zone

    # Force HTTPS for all requests except healthcheck endpoint
    config.force_ssl = true
    config.ssl_options = {
      hsts: { preload: true, expires: 2.year, subdomains: true },
      redirect: {
        exclude: ->(request) { request.path =~ /healthcheck/ },
      },
    }

    # https://github.com/alphagov/govuk-frontend/issues/1350
    config.assets.css_compressor = nil

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Don't generate system test files.
    config.generators.system_tests = nil
    config.eager_load_paths << Rails.root.join("lib")

    # Disable IP spoofing check as we get too many false positives due to proxies
    config.action_dispatch.ip_spoofing_check = false

    # enable customising the full_message method.
    config.active_model.i18n_customize_full_message = true

    config.notify_gateway = Notifications::Client
  end
end

require "action_mailer/railtie"
require_relative "../../lib/gateways/development_notify_gateway"

Rails.application.configure do
  config.notify_gateway = Gateways::DevelopmentNotifyGateway
  config.hosts.clear
  Bullet.enable                      = true
  Bullet.alert                       = true
  Bullet.bullet_logger               = true
  Bullet.console                     = true
  Bullet.rails_logger                = true
  Bullet.add_footer                  = true
  Bullet.unused_eager_loading_enable = true
  Bullet.n_plus_one_query_enable     = true
  Bullet.counter_cache_enable = true

  config.web_console.permissions = %w[172.0.0.0/8 192.168.0.0/16 10.0.0.0/8]

  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.seconds.to_i}",
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = false

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  config.action_mailer.default_url_options = { host: "localhost:3000" }
  config.action_mailer.perform_deliveries = false
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default charset: "utf-8"

  config.force_ssl = false
  config.s3_aws_config = {
    stub_responses: {
      put_object: {},
      get_object: {
        body: '^[a-zA-Z0-9\.-]+@([a-zA-Z0-9-]+\.)*(gov\.uk)$',
      },
    },
  }
  config.route53_aws_config = {
    stub_responses: {
      get_health_check_status: {
        health_check_observations: [
          {
            region: "ap-southeast-2",
            ip_address: "39.239.222.111",
            status_report: {
              status: "Success: HTTP Status Code 200, OK",
            },
          },
        ],
      },
      list_health_checks: {
        max_items: 10,
        marker: "PageMarker",
        is_truncated: false,
        health_checks: [
          {
            caller_reference: "AdminMonitoring",
            id: "abc123",
            health_check_version: 1,
            health_check_config: {
              ip_address: "111.111.111.111",
              measure_latency: false,
              type: "HTTP",
            },
          },
          {
            caller_reference: "AdminMonitoring",
            id: "xyz789",
            health_check_version: 1,
            health_check_config: {
              ip_address: "222.222.222.222",
              measure_latency: false,
              type: "HTTP",
            },
          },
        ],
      },
    },
  }
end

ActionMailer::Base.perform_deliveries = false

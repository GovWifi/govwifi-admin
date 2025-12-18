ruby File.read(".ruby-version").strip

source "https://rubygems.org"

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem "aws-sdk-route53", "~> 1.125.0"
gem "aws-sdk-s3", "~> 1.208.0"
gem "cancancan"
gem "devise", "~> 4.9.4"
gem "devise_zxcvbn", "~> 6.0.0"
gem "elasticsearch", "~> 9.2.0"
gem "google-apis-drive_v3"
gem "govuk-components"
gem "govuk_design_system_formbuilder"
gem "govwifi_two_factor_auth", git: "https://github.com/GovWifi/govwifi_two_factor_auth.git"
gem "httparty", "~> 0.23.1"
gem "mysql2", "~> 0.5.6"
gem "net-imap", require: false
gem "net-pop", require: false
gem "net-smtp", require: false
gem "notifications-ruby-client", "~> 6.3.0"
gem "opensearch-ruby"
gem "puma", "~> 7.1"
gem "rails", "~> 8.0"
gem "rqrcode"
gem "rubyzip"
gem "sassc-rails"
gem "sentry-rails"
gem "sentry-ruby"
gem "sprockets"
gem "tzinfo-data"
gem "uk_postcode", "~> 2.1"
gem "view_component"
gem "zendesk_api"

group :test do
  gem "capybara"
  gem "erb_lint", require: false
  gem "factory_bot_rails"
  gem "faker"
  gem "nokogiri"
  gem "ostruct"
  gem "rack_session_access"
  gem "rails-controller-testing"
  gem "rspec-rails"
  gem "rubocop-govuk"
  gem "shoulda-matchers"
  gem "simplecov", require: false
  gem "simplecov-console", require: false
  gem "timecop"
  gem "webmock"
end

group :development do
  gem "web-console"
end

group :development, :test do
  gem "bullet"
  gem "byebug"
  gem "debug", require: false
  gem "listen"
  gem "pry"
  gem "rack-mini-profiler", require: false
  gem "solargraph"
end

ruby File.read(".ruby-version").strip

source "https://rubygems.org"

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem "aws-sdk-route53", "~> 1.56.0"
gem "aws-sdk-s3", "~> 1.103.0"
gem "cancancan"
gem "devise", "~> 4.8.0"
gem "devise_invitable", "~> 2.0.5"
gem "devise_zxcvbn", "~> 5.1.0"
gem "google-apis-drive_v3"
gem "httparty", "~> 0.20.0"
gem "jquery-rails"
gem "mysql2", "~> 0.5.2"
gem "notifications-ruby-client", "~> 5.3.0"
gem "pagy"
gem "puma", "~> 5.5"
gem "rails", "~> 6.1.4"
gem "rqrcode"
gem "sassc-rails"
gem "sentry-rails"
gem "sentry-ruby"
gem "sprockets"
gem "two_factor_authentication"
gem "tzinfo-data"
gem "uk_postcode", "~> 2.1"
gem "zendesk_api"

group :test do
  gem "capybara"
  gem "erb_lint", require: false
  gem "factory_bot_rails", "~> 6.2.0"
  gem "faker"
  gem "guard-rspec"
  gem "nokogiri"
  gem "rack_session_access"
  gem "rails-controller-testing"
  gem "rspec-rails", "~> 5.0.2"
  gem "rubocop-govuk", "~> 4"
  gem "shoulda-matchers", "~> 5.0"
  gem "simplecov", require: false
  gem "simplecov-console", require: false
  gem "timecop", "~> 0.9.2"
  gem "webmock", "~> 3.14.0"
end

group :development, :test do
  gem "bullet", "~> 6.1"
  gem "byebug", "~> 11"
  gem "listen", "~> 3"
  gem "pry"
  gem "rack-mini-profiler", require: false
  gem "spring-commands-rspec"
end

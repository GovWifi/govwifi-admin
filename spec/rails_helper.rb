# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
require 'capybara/rspec'
require 'support/factory_bot'
require 'webmock/rspec'
require 'selenium-webdriver'
require 'webdrivers'
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.include Warden::Test::Helpers

  config.use_transactional_fixtures = false

  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  Capybara.register_driver :remote_firefox do |app|
  Capybara::Selenium::Driver.new(app,
  :browser => :remote,
  :desired_capabilities => :firefox,
  :url => "http://selenium:4444/wd/hub"
      )
  end

  Capybara.app_host = "http://app:55555"
  Capybara.server_host = "app"
  Capybara.server_port = 55555


  Capybara.javascript_driver = :remote_firefox

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:suite) do
    Webdrivers.logger.level = :DEBUG
    WebMock.disable!
    Webdrivers::Geckodriver.update
    WebMock.enable!
  end

  config.before do
    DatabaseCleaner.strategy = :transaction
    Session.delete_all
  end

  # config.before do
  #   # https://github.com/titusfortner/webdrivers/wiki/Using-with-VCR-or-WebMock

  #   allowed_sites = [
  #     "https://chromedriver.storage.googleapis.com",
  #     "https://github.com/mozilla/geckodriver/releases",
  #     "https://selenium-release.storage.googleapis.com",
  #     "https://developer.microsoft.com/en-us/microsoft-edge/tools/webdriver"
  #   ]

  #   WebMock.disable_net_connect!(allow_localhost: true, allow: allowed_sites)
  # end

  # This block must be here, do not combine with the other `before(:each)` block.
  # This makes it so Capybara can see the database.
  config.before do
    DatabaseCleaner.start
  end
  config.after do
    Warden.test_reset!
    DatabaseCleaner.clean
    Session.delete_all
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

ruby File.read(".ruby-version").strip

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'devise', '~> 4.4.3'
gem 'puma', '~> 3.12'
gem 'rails', '~> 5.1.5'
gem 'sass-rails', '~> 5.0'
gem 'sqlite3'

group :test do
  gem 'capybara'
  gem 'capybara-screenshot'
  gem 'database_cleaner'
  gem 'factory_bot_rails', '~> 4.0'
  gem 'govuk-lint', '~> 3'
  gem 'nokogiri'
  gem 'rspec-rails', '~> 3'
end

group :development, :test do
  gem 'byebug', '~> 10'
  gem 'listen', '~> 3'
  gem 'pry'
end

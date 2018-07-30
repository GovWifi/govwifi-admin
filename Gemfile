ruby File.read(".ruby-version").strip

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'puma', '~> 3.7'
gem 'rails', '~> 5.1.5'
gem 'sass-rails', '~> 5.0'
gem 'sqlite3'
gem 'webpacker', '~> 3.5'

group :development, :test do
  gem 'byebug', '~> 10'
  gem 'govuk-lint', '~> 3'
  gem 'rspec-rails', '~> 3'
end

group :development do
  gem 'listen', '~> 3'
end

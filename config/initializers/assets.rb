# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

Rails.application.config.assets.precompile += %w(
  assets/images/govuk-logotype-crown.png
)


Rails.application.config.assets.paths += [
  Rails.root.join('node_modules/govuk-frontend/assets/images'),
  Rails.root.join('node_modules/govuk-frontend/assets/fonts'),
  Rails.root.join('node_modules/govuk-frontend')
]


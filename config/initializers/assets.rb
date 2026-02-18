# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

Rails.application.config.assets.paths += [
  Rails.root.join("node_modules/accessible-autocomplete/dist"),
  Rails.root.join("node_modules/govuk-frontend/dist/govuk/assets/images"),
  Rails.root.join("node_modules/govuk-frontend/dist/govuk/assets/fonts"),
  Rails.root.join("node_modules/govuk-frontend/dist/govuk"),
  Rails.root.join("node_modules/govwifi-shared-frontend/dist"),
  Rails.root.join("node_modules/html5shiv/dist"),
  Rails.root.join("vendor/assets/stylesheets"),
  Rails.root.join("node_modules/hmrc-frontend/hmrc"),
]

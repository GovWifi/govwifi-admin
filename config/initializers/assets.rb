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

# Use the installed HMRC frontend version so we load the real min bundle (works in CI and locally).
hmrc_path = Rails.root.join("node_modules/hmrc-frontend/hmrc")
hmrc_version = begin
  File.read(hmrc_path.join("VERSION.txt")).strip
rescue Errno::ENOENT
  "6.113.0"
end
Rails.application.config.x.hmrc_frontend_basename = "hmrc-frontend-#{hmrc_version}.min"
Rails.application.config.assets.precompile += [
  "#{Rails.application.config.x.hmrc_frontend_basename}.js",
  "#{Rails.application.config.x.hmrc_frontend_basename}.css",
]

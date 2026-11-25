class SuperAdmin::Locations::MapController < SuperAdminController
  # Google Maps loads its script, map tiles, styles and fonts from Google's
  # domains, so this page needs a more relaxed policy than the rest of the site.
  content_security_policy do |policy|
    policy.script_src :self, "https://maps.googleapis.com"
    policy.img_src :self, :data, "https://*.googleapis.com", "https://*.gstatic.com", "https://*.google.com"
    policy.style_src :self, :unsafe_inline, "https://fonts.googleapis.com"
    policy.font_src :self, :data, "https://fonts.gstatic.com"
    policy.connect_src :self, "https://*.googleapis.com", "https://*.gstatic.com"
  end

  # Google Maps adds inline styles. Browsers ignore 'unsafe-inline' when a
  # nonce is also present, so only use the nonce for scripts on this page.
  before_action { request.content_security_policy_nonce_directives = %w[script-src] }

  def index
    @postcodes = Location.pluck(:postcode)
    @coordinates = Gateways::Coordinates.new(postcodes: @postcodes).fetch_coordinates
  end
end

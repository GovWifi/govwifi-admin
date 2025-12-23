Rails.application.config.content_security_policy do |policy|
  # Handy reference:
  # - https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CSP
  policy.default_src :none
  policy.connect_src :self
  policy.font_src :self, :data
  policy.img_src :self, :data
  policy.object_src :none
  policy.form_action :self
  policy.style_src :self
  policy.script_src :self
  policy.frame_ancestors :none
  policy.base_uri :self
  policy.upgrade_insecure_requests true
  policy.report_uri "/csp-violation-report"
end

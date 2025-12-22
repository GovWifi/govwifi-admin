Rails.application.config.content_security_policy do |policy|
  policy.default_src :self
  policy.font_src :self, :data
  policy.img_src :self, :data
  policy.object_src :none
  policy.script_src :self
  policy.style_src :self, :unsafe_inline
  policy.report_uri "/csp-violation-report"
end

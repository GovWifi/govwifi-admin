Rails.application.config.content_security_policy do |policy|
  # Handy reference:
  # - https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CSP

  # Optional GovWifi AI assistant widget. When CHATBOT_ENABLED is set at
  # boot (see app/views/layouts/application.html.erb), the widget script
  # is loaded from CHATBOT_WIDGET_ORIGIN and it then fetch()es
  # POST /api/v1/chat on that host. Both need CSP allowlisting
  # (script-src for the bundle, connect-src for the SSE stream).
  # Style-src stays :self — the widget's injected <style> element is
  # nonce'd via data-nonce (Rails' nonce generator already covers
  # style-src per config/environments/*.rb).
  chatbot_origin =
    if ENV.fetch("CHATBOT_ENABLED", "false") == "true"
      ENV.fetch("CHATBOT_WIDGET_ORIGIN", "https://assistant.wifi.service.gov.uk")
    end

  policy.default_src :none
  policy.connect_src :self, *[chatbot_origin].compact
  policy.font_src :self, :data
  policy.img_src :self, :data
  policy.object_src :none
  policy.style_src :self
  policy.script_src :self, *[chatbot_origin].compact
  policy.form_action :self
  policy.frame_ancestors :none
  policy.base_uri :self
  policy.upgrade_insecure_requests true
  policy.report_uri "/csp-violation-report"
  # Not yet supported by ruby on rails but will replace report_uri eventually:
  # policy.report_to "/csp-violation-report"
end

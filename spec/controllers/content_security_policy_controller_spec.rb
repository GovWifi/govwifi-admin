require "rails_helper"

RSpec.describe ContentSecurityPolicyController, type: :controller do
  describe "Reporting CSP Violation" do
    context "when a violation is reported" do
      it "It is accepted and no content is returned" do
        post :csp_violation_report, body: {
          "csp-report": {
            "document-uri": "http://example.com/signup.html",
            "referrer": "",
            "violated-directive": "style-src cdn.example.com",
            "effective-directive": "style-src",
            "original-policy": "default-src 'none'; style-src cdn.example.com; report-uri /csp-violation-report",
            "blocked-uri": "http://evil.com/style.css",
          },
        }.to_json, as: :json
        expect(response).to have_http_status(:no_content)
      end
    end
  end
end

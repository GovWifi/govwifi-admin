require "rails_helper"

RSpec.describe WellKnownController, type: :controller do
  describe "Recovering the vulnerability reporting details" do
    context "when the user recovers the site's security.txt" do
      it "redirects to the government hosted security.txt" do
        get :security_txt

        expect(response).to redirect_to("https://vdp.cabinetoffice.gov.uk/.well-known/security.txt")
      end
    end
  end
end

require "rails_helper"

RSpec.describe LocationsController, type: :controller do
  let(:user) { create(:user, :with_organisation, :with_2fa) }
  let(:admin) { create(:user, :with_organisation, :with_2fa) }
  let(:super_admin) { create(:user, :super_admin, :with_organisation, :with_2fa) }
  let(:location) { create(:location, organisation: user.organisations.first) }
  let(:other_location) { create(:location, organisation: create(:organisation)) }
  let(:other_organisation) { admin.organisations.last }

  before do
    sign_in user
  end

  describe "GET /add_ips" do
    context "when the user does not belong to the organisation" do
      it "redirects to the root path" do
        get :add_ips, params: { location_id: other_location.id }

        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /update_ips" do
    let(:params) do
      {
        location_ips_form: {
          ip_1: Faker::Internet.public_ip_v4_address,
          ip_2: Faker::Internet.public_ip_v4_address,
        },
        location_id: location.id,
      }
    end

    context "when the update goes well" do
      before do
        post :update_ips, params:
      end

      it "redirects to the created ips path" do
        expect(response).to redirect_to(ips_path)
      end
    end

    context "when the user is trying to access a location they don't manage" do
      let(:other_location) {  create(:location) }
      let(:other_params) do
        params[:location_id] = other_location.id
        params
      end

      before do
        post :update_ips, params: other_params
      end

      it "redirects them to the root path" do
        expect(response).to redirect_to root_path
      end

      it "does not update the location" do
        expect(other_location.reload.ips).to be_empty
      end
    end
  end

  describe "POST /update" do
    context "when the user does not belong to the requested location" do
      it "redirects to the root path" do
        put :update, params: { id: other_location.id }

        expect(response).to redirect_to(root_path)
      end
    end

    context "when the user belongs to the requested location" do
      it "redirects to the ips path" do
        put :update, params: { id: location.id }

        expect(response).to redirect_to(ips_path)
      end
    end
  end

  describe "POST /update_location" do
    context "when sign_in user is super_admin" do
      before do
        sign_in super_admin
      end

      context "when location's organisation belongs to signed_in user organisation" do
        it "update location and redirect to ips_path " do
          put :update_location, params: { location_id: location.id, location: { organisation_id: user.organisations.first.id, address: location.address, postcode: location.postcode } }
          expect(response).to redirect_to(ips_path)
        end
      end

      context "when location's organisation doesn't belong to signed_in user organisation" do
        it "render exit page with flash alert" do
          put :update_location, params: { location_id: location.id, location: { organisation_id: other_organisation.id, address: location.address, postcode: location.postcode } }
          expect(response).to redirect_to(ips_path)
        end
      end
    end

    context "when sign_in user is not a super_admin" do
      before do
        sign_in user
      end
      context "when location's organisation belongs to signed_in user organisation" do
        it "update location and redirect to ips_path " do
          put :update_location, params: { location_id: location.id, location: { organisation_id: user.organisations.first.id, address: location.address, postcode: location.postcode } }
          expect(response).to redirect_to(ips_path)
        end
      end

      context "when location's organisation doesn't belong to signed_in user organisation" do
        it "render exit page with flash alert" do
          put :update_location, params: { location_id: location.id, location: { organisation_id: other_organisation.id, address: location.address, postcode: location.postcode } }
          expect(flash[:alert]).to match(/You can't update the location to an organisation you're not a member of/)
          expect(response).to redirect_to(ips_path)
        end
      end
    end
  end
end

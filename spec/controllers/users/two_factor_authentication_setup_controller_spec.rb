require 'rails_helper'

RSpec.describe Users::TwoFactorAuthenticationSetupController, type: :controller do
  let(:organisation) { create(:organisation) }

  let(:superadmin) { create(:user, :super_admin) }
  let(:admin) { create(:user, organisations: [organisation]) }
  let(:stranger) { create(:user, :with_organisation) }
  let(:teammate) { create(:user, organisations: [organisation]) }

  describe 'edit' do
    context 'when the current_user is not allowed to edit' do
      before do
        sign_in stranger
        @response = get :edit, params: { id: teammate.id }
      end

      it 'redirects to the home page' do
        expect(response).to redirect_to root_path
      end

      it 'does not assign the user variable' do
        expect(assigns(:user)).to be_nil
      end
    end

    context 'when the user is allowed to edit' do
      before do
        sign_in admin
        @response = get :edit, params: { id: teammate.id }
      end

      it 'renders the right view' do
        expect(response).to render_template 'edit'
      end

      it 'assigns the user variable' do
        expect(assigns(:user)).to eq teammate
      end
    end

    context 'when the user is a super admin' do
      before do
        sign_in superadmin
        @response = get :edit, params: { id: teammate.id }
      end

      it 'renders the right view' do
        expect(response).to render_template 'edit'
      end

      it 'assigns the user variable' do
        expect(assigns(:user)).to eq teammate
      end
    end
  end
end

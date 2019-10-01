describe 'Viewing IP addresses', type: :feature do
  include_context 'with a mocked notifications client'

  let(:user) { create(:user, :with_organisation) }

  context 'with no IPs' do
    before do
      sign_in_user user
    end

    it 'shows no IPs' do
      visit ips_path
      expect(page).to have_content 'You need to add at least one location to offer GovWifi'
    end

    context 'when visiting the root path' do
      before do
        visit root_path
      end

      it_behaves_like 'shows the setup instructions page'
    end
  end

  context 'with IPs' do
    let(:location) { create(:location, organisation: user.organisations.first) }
    let!(:ip) { create(:ip, location: location, created_at: 9.days.ago) }

    before do
      sign_in_user user
      visit ips_path
    end

    it 'shows the RADIUS secret key' do
      expect(page).to have_content(location.radius_secret_key)
    end

    it 'shows the IP' do
      expect(page).to have_content(ip.address)
    end

    it 'shows the locations address' do
      expect(page).to have_content(location.address)
    end

    context 'with inactive IPs' do
      before do
        create(:session, start: (Date.today - 11.days), username: 'abc123', siteIP: ip.address)
        visit ips_path
      end

      it 'labels the IP as inactive' do
        within("#ips-row-#{ip.id}") do
          expect(page).to have_content('No traffic in the last 10 days')
        end
      end
    end

    context 'with newly created IPs with no activity' do
      it 'labels the IP as created but unused' do
        within("#ips-row-#{ip.id}") do
          expect(page).to have_content('No traffic received yet')
        end
      end
    end

    context 'with active IPs' do
      before do
        create(:session, start: Date.today, username: 'abc123', siteIP: ip.address)
        visit ips_path
      end

      it 'Does not label the IP as inactive' do
        within("#ips-row-#{ip.id}") do
          expect(page).not_to have_content('No traffic for the last 10 days')
        end
      end

      it 'Does not label the IP as unused' do
        within("#ips-row-#{ip.id}") do
          expect(page).not_to have_content('No traffic received yet')
        end
      end
    end
  end

  context 'when logged out' do
    before { visit ips_path }

    it_behaves_like 'not signed in'
  end
end

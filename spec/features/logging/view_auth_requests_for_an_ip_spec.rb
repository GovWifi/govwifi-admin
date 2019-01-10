describe 'View authentication requests for an IP' do
  context 'with results' do
    let(:ip) { '1.2.3.4' }
    let(:username) { 'ABCDEF' }
    let(:organisation) { create(:organisation) }
    let(:admin_user) { create(:user, organisation_id: organisation.id) }
    let(:location) { create(:location, organisation_id: organisation.id) }

    before do
      Session.create!(
        start: 3.days.ago,
        username: username,
        siteIP: ip,
        success: true
      )

      create(:ip, location_id: location.id, address: ip)

      sign_in_user admin_user
      visit ips_path

      within('#ips-table') do
        click_on 'View logs'
      end
    end

    context 'searching by IP address' do
      it 'displays the authentication requests' do
        expect(page).to have_content("Found 1 result for \"#{ip}\"")
        expect(page).to have_content(username)
      end
    end
  end
end

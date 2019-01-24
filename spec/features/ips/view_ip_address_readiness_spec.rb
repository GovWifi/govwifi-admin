require 'timecop'

describe 'view whether IPs are ready' do
  include_context 'with a mocked notifications client'

  after { Timecop.return }

  describe 'Viewing IPs' do
    context 'when one has been added' do
      let(:user) { create(:user) }
      let(:t) { DateTime.now.midnight }

      before do
        Timecop.travel(t)
        create :location, organisation: user.organisation
        sign_in_user user
        visit new_ip_path
        fill_in 'address', with: '10.0.0.1'
        click_on 'Add new IP address'
      end

      context 'and I view it immediately' do
        before do
          visit ips_path
        end

        it 'shows it is activating tomorrow' do
          expect(page).to have_content('Not available until 6am tomorrow')
        end
      end

      context 'and I view it after a day has passed' do
        before do
          Ip.all.each do |ip|
            ip.update_attributes(created_at: Date.yesterday)
          end
          sign_in_user user
          visit ips_path
        end

        it 'shows it as available' do
          expect(page).to have_content('Available')
          expect(page).to_not have_content('tomorrow')
        end
      end
    end
  end
end

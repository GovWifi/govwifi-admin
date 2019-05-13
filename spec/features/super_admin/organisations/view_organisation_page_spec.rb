describe 'View details of an organisation', type: :feature do
  let(:organisation) { create(:organisation) }

  context 'when logged in as a super-admin' do
    let(:location_1) { create(:location, organisation: organisation, address: 'Aarry Street') }
    let(:location_2) { create(:location, organisation: organisation, address: 'Carry Street') }
    let(:location_3) { create(:location, organisation: organisation, address: 'Barry Lane') }

    let!(:user_1) { create(:user, name: "Aardvark", organisations: [organisation]) }
    let!(:user_2) { create(:user, name: "Zed", organisations: [organisation]) }
    let!(:user_3) { create(:user, name: "", email: "batman@batcave.com", organisations: [organisation]) }

    before do
      create(:user, organisations: [organisation])

      create(:ip, location: location_1)
      create(:ip, location: location_2)
      create(:ip, location: location_3)

      sign_in_user create(:user, :super_admin)
      visit admin_organisation_path(organisation)
    end

    it 'shows details page for the organisations' do
      expect(page).to have_content(organisation.name)
    end

    it 'has the creation date of the organisation' do
      expect(page).to have_content(
        organisation.created_at.strftime(
          "#{organisation.created_at.day.ordinalize} of %B, %Y"
        )
      )
    end

    it 'has a Usage section' do
      expect(page).to have_content('Usage')
    end

    it 'shows the number of users' do
      within('#user-count') do
        expect(page).to have_content('4')
      end
    end

    it 'lists the users' do
      organisation.users.each do |user|
        expect(page).to have_content(user.name)
      end
    end

    it 'lists all team members in alphabetical order' do
      expect(page.body).to match(/#{user_1.name}.*#{user_3.name}.*#{user_2.email}/m)
    end

    it 'shows the number of locations' do
      within('#location-count') do
        expect(page).to have_content('3')
      end
    end

    it 'lists all locations in alphabetical order' do
      expect(page.body).to match(/#{location_1.address}.*#{location_3.address}.*#{location_2.address}/m)
    end

    it 'shows the number of IPs' do
      within('#ip-count') do
        expect(page).to have_content('3')
      end
    end

    it 'has a service email' do
      expect(page).to have_content(organisation.service_email)
    end

    context 'when an MoU does not exist' do
      it 'says no MoU exists' do
        expect(page).to have_content('This organisation has not uploaded an MoU.')
      end

      it 'has an Upload MoU button' do
        within('#mou-upload-form') do
          expect(find_button('Upload MOU')).to be_present
        end
      end
    end

    context 'when an MoU exists' do
      before do
        organisation.signed_mou.attach(
          io: File.open(Rails.root + 'spec/fixtures/mou.pdf'), filename: 'mou.pdf'
        )
        visit admin_organisation_path(organisation)
      end

      it 'has a download button' do
        expect(page).to have_link('download and view the document.')
      end

      it 'has upload date' do
        expect(page).to have_content(
          'A signed MoU was uploaded on ' +
            organisation.signed_mou.attachment.created_at.strftime('%-e %b %Y')
        )
      end

      it 'has a replace MoU button' do
        within('#mou-upload-form') do
          expect(find_button('Replace')).to be_present
        end
      end
    end
  end

  context 'when logged out' do
    before { visit admin_organisation_path(organisation) }

    it_behaves_like 'not signed in'
  end

  context 'when logged in as a normal user' do
    before do
      sign_in_user create(:user, :with_organisation)
      visit admin_organisation_path(organisation)
    end

    it_behaves_like 'user not authorised'
  end
end

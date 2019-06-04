describe 'Register an additional organisation', type: :feature do
  let(:organisation_1) { create(:organisation) }
  let(:user) { create(:user, organisations: [organisation_1]) }

  before do
    sign_in_user user
    visit change_organisation_path
  end

  it 'shows the create organisation button on the switch organisation page' do
    expect(page).to have_button('Add new organisation')
  end

  it 'displays the new organisation form' do
    click_on 'Add new organisation'
    expect(page).to have_content("Register an organisation for GovWifi")
  end

  context 'when submitting the form with correct info' do
    let(:organisation_2_name) { "Gov Org 3" }

    before do
      click_on 'Add new organisation'
      select organisation_2_name, from: 'name'
      fill_in 'Service email', with: "info@gov.uk"
    end

    it 'creates the organisation' do
      expect { click_on 'Create organisation' }.to change(Organisation, :count).by(1)
    end

    it 'associates the organisation to the user' do
      click_on 'Create organisation'
      expect(user.reload.organisations.map(&:name)).to eq([organisation_1.name, organisation_2_name])
    end

    it 'displays the success message to the user' do
      click_on 'Create organisation'
      expect(page).to have_content("#{organisation_2_name} created")
    end

    it 'sets the new organisation as the current organisation' do
      click_on 'Create organisation'
      within ".subnav" do
        expect(page).to have_content(organisation_2_name)
      end
    end

    it 'confirms the membership that joins the user to the organisation' do
      click_on 'Create organisation'
      organisation = user.organisations.find_by(name: organisation_2_name)
      expect(user.membership_for(organisation)).to be_confirmed
    end

    it 'gives the user can_manage_team privileges' do
      click_on 'Create organisation'
      organisation = user.organisations.find_by(name: organisation_2_name)
      expect(user.can_manage_team?(organisation)).to eq(true)
    end

    it 'gives the user can_manage_locations privileges' do
      click_on 'Create organisation'
      organisation = user.organisations.find_by(name: organisation_2_name)
      expect(user.can_manage_locations?(organisation)).to eq(true)
    end
  end

  context 'when submitting the form with invalid data' do
    before do
      click_on 'Add new organisation'
      select organisation_2_name, from: 'name'
      fill_in 'Service email', with: service_email
    end

    context 'with an invalid service email' do
      let(:organisation_2_name) { "Gov Org 3" }
      let(:service_email) { "" }

      it 'does not create the organisation' do
        expect { click_on 'Create organisation' }.to change(Organisation, :count).by(0)
      end

      it 'displays the correct error to the user' do
        click_on 'Create organisation'
        expect(page).to have_content("Service email must be a valid email address")
      end
    end

    context 'with an invalid organisation name' do
      let(:organisation_2_name) { "" }
      let(:service_email) { "info@gov.uk" }

      it 'does not create the organisation' do
        expect { click_on 'Create organisation' }.to change(Organisation, :count).by(0)
      end

      it 'displays the correct error to the user' do
        click_on 'Create organisation'
        expect(page).to have_content("Name can't be blank")
      end
    end
  end
end

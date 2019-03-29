describe Organisation do
  context 'associations' do
    it { is_expected.to have_many(:users) }
    it { is_expected.to have_many(:locations) }

    context 'when deleting an organisation as an admin' do
      let(:org) { create(:organisation) }
      let!(:user) { create(:user, organisation: org) }
      let!(:location) { create(:location, organisation: org) }
      let!(:ip) { Ip.create(address: "1.1.1.1", location: location) }

      it 'removes all of its children ' do
        org.destroy
        expect { user.reload }.to raise_error ActiveRecord::RecordNotFound
        expect { location.reload }.to raise_error ActiveRecord::RecordNotFound
        expect { ip.reload }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    context 'When an organisation signs up under the same name as another organisation' do
      before { create(:organisation, name: 'Gov Org 1') }

      it 'is not valid' do
        organisation = build(:organisation, name: 'Gov Org 1')
        expect(organisation).not_to be_valid
      end
    end

    context 'When updating the organisations service email' do
      it 'does not validate the organisations name' do
        organisation = create(:organisation)
        organisation.service_email = 'newserviceemail@gov.uk'
        expect(organisation).to be_valid
      end
    end

    context 'when my organisation is in the GovUk register' do
      it 'is valid' do
        organisation = build(:organisation, name: 'Gov Org 1')
        expect(organisation).to be_valid
      end
    end

    context 'when my organisation is not in the GovUk register' do
      let(:organisation) { build(:organisation, name: 'Some invalid organisation name') }

      it 'is not valid' do
        expect(organisation).not_to be_valid
      end

      it 'explains why it is invalid' do
        organisation.valid?
        expect(organisation.errors.full_messages).to eq([
          "#{organisation.name} isn't a whitelisted organisation"
        ])
      end
    end

    context 'when organisation name is left blank' do
      let(:organisation) { build(:organisation, name: '') }

      it 'is invalid' do
        expect(organisation).not_to be_valid
      end

      it 'explains why it is invalid' do
        organisation.valid?
        expect(organisation.errors.full_messages).to eq([
          "Name can't be blank"
        ])
      end
    end
  end
end

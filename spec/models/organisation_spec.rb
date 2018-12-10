describe Organisation do
  context 'associations' do
    it { should have_many(:users) }
    it { should have_many(:locations) }
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).case_insensitive }

    it "requires a unique name regardless of case" do
      Organisation.create(name: "Parks & Rec Dept")
      expect {
        Organisation.create(name: "parks & rec dept")
      }.to change { Organisation.count }.by(0)
    end

    context 'when deleting an organisation as an admin' do
      let!(:org) { create(:organisation) }
      let!(:user1) { create(:user, organisation: org) }
      let!(:location1) { create(:location, organisation: org) }
      let!(:ip1) { Ip.create(address: "1.1.1.1", location: location1) }

      it 'removes all of its children ' do
        org.destroy
        expect { user1.reload }.to raise_error ActiveRecord::RecordNotFound
        expect { location1.reload }.to raise_error ActiveRecord::RecordNotFound
        expect { ip1.reload }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end
end

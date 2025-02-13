describe UseCases::DeleteInactiveUnconfirmed do
  subject { UseCases::DeleteInactiveUnconfirmed }
  let(:inactive_period) { 2.weeks }
  describe "There are no unconfirmed users" do
    before do
      create(:user)
    end
    it "does not delete any users" do
      expect { subject.execute(inactive_period) }.to_not change(User, :count)
    end
  end
  describe "There is an inactive unconfirmed user who has been inactive for less than the specified period" do
    before do
      create(:user, :unconfirmed, created_at: 1.week.ago).id
    end
    it "does not delete any users" do
      expect { subject.execute(inactive_period) }.to_not change(User, :count)
    end
  end
  describe "There is an unconfirmed user who has been inactive for more than the specified period" do
    before do
      @inactive_user_id = create(:user, :unconfirmed, created_at: 3.weeks.ago).id
    end
    it "deletes the unconfirmed user" do
      subject.execute(inactive_period)
      expect(User.where(id: @inactive_user_id)).to_not exist
    end
  end
  describe "There is a mix of unconfirmed and unconfirmed users" do
    before do
      create_list(:user, 2, :unconfirmed, created_at: 1.week.ago)
      create_list(:user, 3, :unconfirmed, created_at: 3.weeks.ago)
      create_list(:user, 7, created_at: 3.weeks.ago)
    end
    it "deletes the inactive unconfirmed users only" do
      expect { subject.execute(inactive_period) }.to change(User, :count).by(-3)
    end
  end
end

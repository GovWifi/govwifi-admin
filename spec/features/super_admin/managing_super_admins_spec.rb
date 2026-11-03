describe "Managing super admins", type: :feature do
  let!(:super_admin) { create(:user, :super_admin) }
  let!(:user) { create(:user, name: "Alice") }

  describe "the list of super admins" do
    before do
      sign_in_user super_admin
      visit root_path

      click_on "View All Organisations"
      click_on "Super Admins"
    end

    context "when user is not a super admin" do
      it "should include the super admin user" do
        expect(page).to have_content(super_admin.name)
      end

      it "should not include user" do
        expect(page).to_not have_content(user.name)
      end

      it "should support making user a super admin" do
        click_on "Add super admin"

        fill_in "Email address", with: user.email

        click_on "Make super admin"

        expect(page).to have_content "#{user.name} is now a super admin"
      end
    end

    context "when user is a super admin" do
      let!(:user) { create(:user, :super_admin, name: "Alice") }

      it "should include user in the list of super admins" do
        expect(page).to have_content(user.name)
      end

      it "should support removing user as a super admin" do
        within(:xpath, "//ul[contains(@class, 'membership-list')]/li[2]") do
          click_on "Remove"
        end

        expect(page).to have_content("Confirm remove super admin privileges for #{user.name}")

        click_on "Remove super admin privileges"

        expect(page).to have_content("#{user.name} (#{user.email}) is no longer a super admin")
      end
    end
  end
end

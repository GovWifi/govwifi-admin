describe "Resign MOU flow", type: :feature do
  let(:user) { create(:user, :with_organisation) }
  let(:organisation) { user.organisations.first }

  before do
    create(:mou, organisation:, version: Mou.latest_known_version)
    sign_in_user user
  end

  it "allows an organisation to re-sign the MOU while keeping the previous record" do
    visit settings_path
    click_link "Review"

    expect(page).to have_current_path(review_mou_settings_path)
    expect(page).to have_content("Review the MOU")
    click_on "Re-sign"

    expect(page).to have_current_path(confirm_resign_mou_settings_path)
    expect(page).to have_content("Re-sign the MOU")
    click_button "Re-sign the MOU"

    expect(page).to have_current_path(show_options_mous_path)
    expect(page).to have_content("Your organisation must sign the memorandum of understanding again.")
    expect(organisation.reload.mou_resign_required_at).to be_present
    expect(organisation.mous.count).to eq(1)
  end

  it "shows Not signed on settings while re-sign is pending" do
    organisation.update!(mou_resign_required_at: Time.zone.now)
    visit settings_path
    expect(page).to have_content("Not signed")
  end
end

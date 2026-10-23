describe "POST /settings/resign_mou", type: :request do
  let(:user) { create(:user, :with_organisation) }
  let(:organisation) { user.organisations.first }
  let(:mou) { create(:mou, organisation:, version: Mou.latest_known_version) }

  before do
    https!
    sign_in_user(user)
  end

  it "sets mou_resign_required_at on the organisation" do
    expect {
      post resign_mou_settings_path
    }.to change { organisation.reload.mou_resign_required_at }.from(nil).to(be_present)
  end

  it "does not remove the existing MOU" do
    mou
    expect {
      post resign_mou_settings_path
    }.not_to change(Mou, :count)
    expect(Mou.find_by(id: mou.id)).to be_present
  end

  it "redirects to show_options_mous_path with a notice" do
    post resign_mou_settings_path
    expect(response).to redirect_to(show_options_mous_path)
    expect(flash[:notice]).to eq("Your organisation must sign the memorandum of understanding again.")
  end
end

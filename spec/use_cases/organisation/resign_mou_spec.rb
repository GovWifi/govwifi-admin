describe UseCases::Organisation::ResignMou do
  let(:organisation) { create(:organisation) }
  let(:use_case) { described_class.new(organisation_id: organisation.id) }

  it "sets mou_resign_required_at on the organisation" do
    expect {
      use_case.execute
    }.to change { organisation.reload.mou_resign_required_at }.from(nil).to(be_present)
  end
end

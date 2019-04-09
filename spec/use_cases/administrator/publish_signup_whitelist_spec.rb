class DummyWhitelistPresenter
  def execute(payload)
    payload.join('*')
  end
end

describe UseCases::Administrator::PublishSignupWhitelist do
  let(:source_gateway) do
    instance_double(
      Gateways::AuthorisedEmailDomains,
      fetch_domains: %i(gov.org.uk nhs.uk)
    )
  end
  let(:s3_gateway) { instance_spy(Gateways::S3) }
  let(:formatted_s3_payload) { 'gov.org.uk*nhs.uk' }
  let(:presenter) { DummyWhitelistPresenter.new }

  before do
    described_class.new(
      destination_gateway: s3_gateway,
      source_gateway: source_gateway,
      presenter: presenter
    ).execute
  end

  it 'publishes the email domain whitelist' do
    expect(s3_gateway).to have_received(:write).with(data: formatted_s3_payload)
  end
end

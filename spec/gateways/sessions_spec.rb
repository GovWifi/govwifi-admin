describe Gateways::Sessions do
  subject(:session_gateway) { described_class.new(ip_filter: my_ips) }

  let(:my_ips) { ['127.0.0.1', '127.0.0.2', '127.0.0.3', '127.0.0.4', '127.0.0.5'] }
  let(:today_date) { Time.now.to_s }
  let(:yesterday) { (Time.now - 1.day).to_s }
  let(:two_days_ago) { (Time.now - 2.days).to_s }
  let(:three_weeks_ago) { (Time.now - 3.weeks).to_s }
  let(:username) { 'BOBABC' }

  context 'when searching by username' do
    context 'when recent log entries contain none of my IP addresses' do
      before do
        Session.create(start: today_date, username: username, siteIP: '7.7.7.7')
      end

      it 'finds no results' do
        result = session_gateway.search(username: username)
        expect(result).to be_empty
      end
    end

    context 'when recent log entries contain only one of my IP addresses' do
      let(:expected_result) {
        [
          {
            ap: nil,
            mac: nil,
            site_ip: '127.0.0.1',
            start: today_date,
            success: true,
            username: 'BOBABC'
          }, {
            ap: nil,
            mac: nil,
            site_ip: '127.0.0.1',
            start: yesterday,
            success: true,
            username: 'BOBABC'
          }
        ]
      }

      before do
        Session.create(start: today_date, success: true, username: username, siteIP: '127.0.0.1')
      end

      it 'finds one result' do
        results = session_gateway.search(username: username)

        expect(results.count).to eq(1)
      end

      it 'finds multiple results' do
        Session.create(start: yesterday, success: true, username: username, siteIP: '127.0.0.1')

        expect(session_gateway.search(username: 'BOBABC')).to eq(expected_result)
      end
    end

    context 'when recent log entries contain any number of my IP addresses' do
      it 'only selects logs matching my IP addresses' do
        Session.create(start: today_date, username: username, siteIP: '127.0.0.1')
        Session.create(start: today_date, username: username, siteIP: '127.0.0.4')
        Session.create(start: today_date, username: username, siteIP: '3.3.3.3')

        result = session_gateway.search(username: username)
        expect(result.count).to eq(2)
      end
    end

    context 'when viewing the results' do
      let!(:last_result) { Session.create(start: two_days_ago, username: username, ap: 'ap3', siteIP: '127.0.0.1') }
      let!(:first_result) { Session.create(start: today_date, username: username, ap: 'ap1', siteIP: '127.0.0.1') }
      let!(:middle_result) { Session.create(start: yesterday, username: username, ap: 'ap2', siteIP: '127.0.0.1') }

      it 'displays the newest logs first' do
        result = session_gateway.search(username: username)
        results_start_array = [result.first[:start], result.second[:start], result.last[:start]]

        expect(results_start_array).to eq([first_result.start, middle_result.start, last_result.start])
      end
    end
  end

  context 'when searching by IP address' do
    before do
      ['127.0.0.1', '127.0.0.2', '3.3.3.3'].each do |ip|
        Session.create(start: today_date, username: username, siteIP: ip)
      end
    end

    it 'finds logs for a particular IP' do
      result = session_gateway.search(username: nil, ips: '127.0.0.1')
      expect(result.count).to eq(1)
    end

    it 'finds logs for any of my organisation IPs' do
      result = session_gateway.search(username: nil, ips: ['127.0.0.1', '127.0.0.2'])
      expect(result.count).to eq(2)
    end

    it 'doesn\'t allow searching by another organisations IP' do
      result = session_gateway.search(username: nil, ips: '3.3.3.3')
      expect(result).to be_empty
    end
  end

  context 'when searching for logs older than two weeks' do
    before do
      Session.create(start: three_weeks_ago, success: true, username: 'FOOBAR', siteIP: '127.0.0.1')
    end

    it 'returns no results' do
      expect(session_gateway.search(username: 'FOOBAR').count).to eq(0)
    end
  end
end

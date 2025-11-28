describe UseCases::Administrator::CheckIfValidIp do
  subject(:use_case) { described_class.new }

  let(:success_result) { use_case.execute(address)[:success] }
  let(:error_message) { use_case.execute(address)[:error_message] }

  context "when invalid" do
    context "with an invalid IP address" do
      let(:address) { "incorrectIP" }

      it "returns false" do
        expect(success_result).to eq(false)
      end

      it "returns a custom error message" do
        expect(error_message).to eq("'#{address}' is not a valid IP address")
      end
    end

    context "with a private IP address" do
      let(:address) { "10.255.255.255" }

      it "returns false" do
        expect(success_result).to eq(false)
      end

      it "returns a custom error message" do
        expect(error_message).to eq("'#{address}' is a private IP address. Only public IPv4 addresses can be added.")
      end
    end

    context "when ALLOW_PRIVATE_IP_FOR_LOCATION is set in the development environment" do
      let(:address) { "192.168.1.10" }

      around do |my_test_case|
        ENV["DEPLOY_ENV"] = "development"
        # Value doesn't matter, just the presence of the variable:
        ENV["ALLOW_PRIVATE_IP_FOR_LOCATION"] = "true"

        my_test_case.run

        ENV.delete("DEPLOY_ENV")
        ENV.delete("ALLOW_PRIVATE_IP_FOR_LOCATION")
      end

      it "returns true (allows the private IP)" do
        expect(success_result).to eq(true)
      end

      it "does not return an error message" do
        expect(error_message).to be_nil
      end
    end

    context "when ALLOW_PRIVATE_IP_FOR_LOCATION is set in a non development environment" do
      let(:address) { "192.168.1.10" }

      around do |my_test_case|
        ENV["DEPLOY_ENV"] = "production"
        ENV["ALLOW_PRIVATE_IP_FOR_LOCATION"] = "true"

        my_test_case.run

        ENV.delete("DEPLOY_ENV")
        ENV.delete("ALLOW_PRIVATE_IP_FOR_LOCATION")
      end

      it "returns false and does not allow private IP addresses" do
        expect(success_result).to eq(false)
      end

      it "does return an error message" do
        expect(error_message).to eq("'#{address}' is a private IP address. Only public IPv4 addresses can be added.")
      end
    end

    context "with an empty string" do
      let(:address) { "" }

      it "returns false" do
        expect(success_result).to eq(false)
      end
    end

    context "with nil" do
      let(:address) { nil }

      it "returns false" do
        expect(success_result).to eq(false)
      end
    end

    context "with a trailing dot" do
      let(:address) { "172.16.254.1." }

      it "returns false" do
        expect(success_result).to eq(false)
      end
    end

    context "with trailing whitespace" do
      let(:address) { "172.16.254.1 " }

      it "returns false" do
        expect(success_result).to eq(false)
      end
    end

    context "with a mistyped IP address" do
      let(:address) { "192.618.0.1" }

      it "returns false" do
        expect(success_result).to eq(false)
      end
    end

    context "with a loopback IP address" do
      let(:address) { "127.0.0.1" }

      it "returns false" do
        expect(success_result).to eq(false)
      end
    end
  end

  context "when not an IPv4" do
    context "with a valid subnet IPv4 address" do
      let(:address) { "192.168.1.15/24" }

      it "returns false" do
        expect(success_result).to eq(false)
      end
    end

    context "with a valid IPv6 address" do
      let(:address) { "2001:db8:0:1234:0:567:8:1" }

      it "returns false" do
        expect(success_result).to eq(false)
      end

      it "returns a custom error message" do
        expect(error_message).to eq("'#{address}' is an IPv6 address. Only IPv4 addresses can be added.")
      end
    end
  end

  context "when valid" do
    context "with a valid IPv4 address" do
      let(:address) { "141.0.149.130" }

      it "returns true" do
        expect(success_result).to eq(true)
      end

      it "does not return a custom error message" do
        expect(error_message).to eq(nil)
      end
    end
  end
end

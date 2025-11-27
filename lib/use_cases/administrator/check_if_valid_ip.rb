module UseCases
  module Administrator
    class CheckIfValidIp
      def execute(address)
        @address = address
        { success: valid_ipv4_address?, error_message: custom_error_message, error_type: }
      end

    private

      attr_reader :address

      def valid_ipv4_address?
        address.present? &&
          address_is_ipv4? &&
          address_is_not_subnet? &&
          address_does_not_allows_all? &&
          address_is_not_loopback? &&
          address_is_not_private?
      end

      def valid_ipv6_address?
        address.present? &&
          address_is_ipv6? &&
          address_is_not_subnet? &&
          address_does_not_allows_all? &&
          address_is_not_loopback? &&
          address_is_not_private?
      end

      def private_ip_address?
        address.present? &&
          address_is_ipv4? &&
          !address_is_not_private?
      end

      def error_type
        return :ipv6 if valid_ipv6_address?
        return :private if private_ip_address?

        :malformed unless valid_ipv4_address?
      end

      def custom_error_message
        return "'#{address}' is an IPv6 address. Only IPv4 addresses can be added." if valid_ipv6_address?

        return "'#{address}' is a private IP address. Only public IPv4 addresses can be added." if private_ip_address?

        "'#{address}' is not a valid IP address" unless valid_ipv4_address?
      end

      def address_does_not_allows_all?
        !address.match?("0.0.0.0")
      end

      def address_is_not_subnet?
        !address.include?("/")
      end

      def address_is_ipv4?
        IPAddr.new(address).ipv4?
      rescue IPAddr::InvalidAddressError
        false
      end

      def address_is_ipv6?
        IPAddr.new(address).ipv6?
      rescue IPAddr::InvalidAddressError
        false
      end

      def address_is_not_loopback?
        !IPAddr.new(address).loopback?
      end

      def address_is_not_private?
        # If the environment variable ALLOW_LOCATION_PRIVATE_ADDRESS_USE is set, we will
        # allow the use of private IP addresses. This is used in the local
        # testing environment.
        if ENV['ALLOW_LOCATION_PRIVATE_ADDRESS_USE']
          puts "ALLOW_LOCATION_PRIVATE_ADDRESS_USE is set, allowing private IP address #{address}"
          true
        else
          !IPAddr.new(address).private?
        end
      end
    end
  end
end

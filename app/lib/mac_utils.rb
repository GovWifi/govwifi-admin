# frozen_string_literal: true

# Utility for normalising MAC addresses.
#
# Removes all non-alphanumeric characters, uppercases, and inserts dashes
# every two characters to match IEEE 802 format (e.g., 50-A6-7F-84-9C-D1).
#
# Usage:
#   MacUtils.normalize("b9:e0-ba:aa:08:7e")  # => "B9-E0-BA-AA-08-7E"
#   MacUtils.normalize("B9E0BA")            # => "B9-E0-BA"
module MacUtils
  MAC_REGEX = /\A[0-9A-Fa-f]{2}([-:]?[0-9A-Fa-f]{2}){5}\z/

  class << self
    # Normalise a raw MAC string into the standard hyphenated format.
    # Returns nil if the input is nil or blank.
    def normalize(mac)
      return nil if mac.nil? || mac.to_s.strip.empty?

      mac.gsub(/[^0-9A-Fa-f]/, "").upcase.scan(/../).join("-")
    end

    # Validate a MAC address string. Returns true if valid, false otherwise.
    def valid?(mac)
      !mac.nil? && MAC_REGEX.match?(mac)
    end
  end
end

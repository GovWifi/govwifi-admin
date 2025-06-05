class LogSearchForm
  IP_FILTER_OPTION = "ip".freeze
  USERNAME_FILTER_OPTION = "username".freeze
  LOCATION_FILTER_OPTION = "location".freeze
  MAC_FILTER_OPTION = "mac".freeze

  include ActiveModel::Model

  attr_accessor :filter_option, :success, :authentication_method
  attr_writer :ip, :username, :location_id, :mac

  validates :filter_option, presence: true
  validates :username,
            length: { in: 5..6, message: "Search term must be 5 or 6 characters" },
            if: -> { filter_option == USERNAME_FILTER_OPTION }
  validates :mac,
            format: { with: /\A(?:[0-9A-Fa-f]{2}([-:]?)){5}[0-9A-Fa-f]{2}\z/, message: "Enter a valid MAC address" },
            if: -> { filter_option == MAC_FILTER_OPTION }
  validates :ip, with: :validate_ip, if: -> { filter_option == IP_FILTER_OPTION }

  def ip
    filter_option == IP_FILTER_OPTION ? @ip : nil
  end

  def username
    filter_option == USERNAME_FILTER_OPTION ? @username : nil
  end

  def location_id
    filter_option == LOCATION_FILTER_OPTION ? @location_id : nil
  end

  def ordered_locations_of(current_organisation)
    current_organisation.locations.order([:address])
  end

  def mac
    filter_option == MAC_FILTER_OPTION ? @mac : nil
  end

private

  def validate_ip
    ip_check = UseCases::Administrator::CheckIfValidIp.new.execute(ip)
    unless ip_check[:success]
      errors.add(:ip, "Enter an IP address in the correct format")
    end
  end
end

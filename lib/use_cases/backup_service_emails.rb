require "csv"

module UseCases
  class BackupServiceEmails
    def initialize(writer:)
      @writer = writer
    end

    def execute
      csv = ::Organisation.all
              .map { |o| [o.name, o.service_email].to_csv }
              .join

      time = Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")

      @writer.write(
        file_name: "#{Deploy.env}-#{time}.csv",
        folder_name: "GovWifi Service Address Backup",
        upload_source: StringIO.new(csv),
        mime_type: "application/csv",
      )
    end
  end
end

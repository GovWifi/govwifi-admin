require "zip"

module UseCases
  class CertificateExporter
    def self.export
      zip_output = StringIO.new
      io = Zip::OutputStream.new(zip_output, stream: true)
      Certificate.includes(:organisation).all.reject(&:has_child?).each do |certificate|
        io.put_next_entry("#{certificate.organisation.name}_#{certificate.name}.pem")
        io.write certificate.content
      end
      io.close
      zip_output.rewind
      Gateways::S3.new(**Gateways::S3::CERTIFICATES).write(zip_output)
    end
  end
end

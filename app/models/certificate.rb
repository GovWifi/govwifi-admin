class Certificate < ApplicationRecord
  belongs_to :organisation

  validates :name, presence: true, uniqueness: { scope: :organisation_id }
  validates :fingerprint, presence: true, uniqueness: { scope: :organisation_id }

  validates :content, :subject, :issuer, :not_before, :not_after, :serial, presence: true

  def name=(value)
    super(value.to_s.squish)
  end

  def root_cert?
    subject == issuer
  end

  def expired?
    Time.zone.now.after?(not_after)
  end

  def nearly_expired?(days)
    warning_start_date = not_after.days_ago(days)
    Time.zone.now.after?(warning_start_date)
  end

  def not_yet_valid?
    not_before.after?(Time.zone.now)
  end

  def public_key
    OpenSSL::X509::Certificate.new(content).public_key
  end

  def verify(issuing_certificate)
    OpenSSL::X509::Certificate.new(content).verify issuing_certificate.public_key
  end

  def has_parent?
    return true if root_cert?

    parents = Certificate.where(subject: issuer, organisation:)
    first_parent = parents.find do |parent|
      verify(parent)
    end
    !!first_parent
  end

  def has_child?
    children = Certificate.where(issuer: subject, organisation:).where.not(subject:)
    first_child = children.find do |child|
      child.verify self
    end
    !!first_child
  end

  def self.parse_certificate(content)
    return if content.nil?

    Certificate.new.tap do |certificate|
      certificate.content = content
      x509_certificate = OpenSSL::X509::Certificate.new(content)
      certificate.fingerprint = OpenSSL::Digest::SHA1.new(x509_certificate.to_der).to_s
      certificate.subject = x509_certificate.subject.to_s
      certificate.issuer = x509_certificate.issuer.to_s
      certificate.not_before = x509_certificate.not_before
      certificate.not_after = x509_certificate.not_after
      certificate.serial = x509_certificate.serial.to_s
    end
  end
end

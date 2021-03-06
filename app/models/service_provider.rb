class ServiceProvider < ApplicationRecord
  # Do not define validations in this model.
  # See https://github.com/18F/identity-validations
  include IdentityValidations::ServiceProviderValidation
  include ActionView::Helpers::SanitizeHelper

  has_paper_trail on: %i[create update destroy]

  attr_readonly :issuer
  attr_writer :issuer_department, :issuer_app

  belongs_to :user
  belongs_to :team, foreign_key: 'group_id', inverse_of: :service_providers

  has_one :agency, through: :team

  has_one_attached :logo_file
  validate :logo_file_mime_type

  enum block_encryption: { 'none' => 0, 'aes256-cbc' => 1 }, _suffix: 'encryption'
  enum identity_protocol: { openid_connect: 0, saml: 1 }

  before_validation(on: %i[create update]) do
    self.attribute_bundle = attribute_bundle.reject(&:blank?) if attribute_bundle.present?
  end

  before_save :sanitize_help_text_content

  def ial_friendly
    case ial
    when 1, nil
      'IAL1'
    when 2
      'IAL2'
    else
      ial.inspect
    end
  end

  # rubocop:disable MethodLength
  def self.possible_attributes
    possible = %w[
      email
      first_name
      middle_name
      last_name
      address1
      address2
      city
      state
      zipcode
      dob
      ssn
      phone
      x509_subject
      x509_presented
    ]
    Hash[*possible.collect { |v| [v, v] }.flatten]
  end
  # rubocop:enable MethodLength

  def recently_approved?
    previous_changes.key?(:approved) && previous_changes[:approved].last == true
  end

  def redirect_uris=(uris)
    super uris.select(&:present?)
  end

  def certificate
    @certificate ||= begin
      if saml_client_cert
        ServiceProviderCertificate.new saml_client_cert
      else
        null_certificate
      end
    rescue OpenSSL::X509::CertificateError
      null_certificate
    end
  end

  private

  def sanitize_help_text_content
    sections = [help_text['sign_in'], help_text['sign_up'], help_text['forgot_password']]
    sections.each { |section| sanitize_section(section) }
  end

  def sanitize_section(section)
    section.transform_values! do |translation|
      sanitize translation, tags: %w[a b br p], attributes: %w[href]
    end
  end

  # rubocop:disable Rails/TimeZone
  def null_certificate
    time = Time.new(0)
    OpenStruct.new(
      issuer: 'Null Certificate',
      not_before: time,
      not_after: time
    )
  end
  # rubocop:enable Rails/TimeZone

  def logo_file_mime_type
    return unless logo_file.attached?
    return if mime_type_valid?
    errors.add(:logo_file, "The file you uploaded (#{logo_file.filename}) is not a PNG or SVG")
    logo_file.purge
  end

  def mime_type_valid?
    logo_file.content_type.in?(ServiceProviderHelper::SP_VALID_LOGO_MIME_TYPES)
  end
end

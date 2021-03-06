require 'login_gov/hostdata'
require 'subprocess'

# rubocop:disable Metrics/ClassLength
class ServiceProviderLogoUpdater
  include ServiceProviderHelper

  IDP_CONFIG_CHECKOUT_NAME = 'identity-idp-config'.freeze

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def import_logos_to_active_storage
    return unless Figaro.env.logo_upload_enabled

    git_latest_idp_config
    idp_config.each do |sp|
      issuer = sp['issuer']
      logo_name = sp['logo']
      logger.info(issuer.to_s + ' logo: ' + logo_name.to_s)
      next unless valid_logo?(logo_name)

      service_provider = ServiceProvider.find_by(issuer: issuer)
      next unless service_provider && File.file?(logo_path(logo_name))

      service_provider.logo_file.attach(
        io: File.open(logo_path(logo_name)),
        filename: logo_name,
        content_type: mime_type(logo_name)
      )
      push_logo_content_type(service_provider)
    end
  rescue StandardError => error
    handle_error(error)
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  private

  # Clone the private-but-not-secret git repo
  def git_latest_idp_config
    if File.directory? repo_dir
      update_repo
    else
      clone_repo
    end
  end

  def idp_config
    @idp_config ||= load_idp_config
  end

  def valid_logo?(logo_name)
    logo_name.present? &&
      valid_image_type?(logo_name) &&
      File.file?(logo_path(logo_name))
  end

  def handle_error(error)
    logger.error(error)
  end

  def logo_path(filename)
    Rails.root.join(
      'identity-idp-config',
      'public',
      'assets',
      'images',
      'sp-logos',
      filename
    )
  end

  def push_logo_content_type(service_provider)
    # Set the content-type on the S3 blob or SVG's won't work
    bucket = Figaro.env.aws_logo_bucket
    key = service_provider.logo_file.key
    s3.copy_object(
      bucket:             bucket,
      content_type:       service_provider.logo_file.content_type,
      copy_source:        "#{bucket}/#{key}",
      key:                key,
      metadata_directive: 'REPLACE',
      acl:                'public-read'
    )
  end

  #############################################################################

  def update_repo
    Dir.chdir(repo_dir) do
      cmd = %w[git pull]
      logger.info(cmd.join(' '))
      Subprocess.check_call(cmd)
    end
  end

  def clone_repo
    repo_url = ENV.fetch('idp_private_config_repo',
                         'git@github.com:18F/identity-idp-config.git')
    cmd = ['git', 'clone', repo_url.to_s, repo_dir.to_s]
    logger.info(cmd.join(' '))
    Subprocess.check_call(cmd)
  end

  def load_idp_config
    url = dashboard_sp_url

    req = RestClient::Request.new(url: url, method: :get, timeout: 2)
    response = req.execute
    JSON.parse(response.body)
  end

  def logger
    @logger ||= default_logger
  end

  def s3
    @s3 ||= Aws::S3::Client.new(region: Figaro.env.aws_region)
  end

  #############################################################################

  def repo_dir
    @repo_dir ||= Rails.root.join(IDP_CONFIG_CHECKOUT_NAME)
  end

  def dashboard_sp_url
    if LoginGov::Hostdata.in_datacenter?
      env = LoginGov::Hostdata.env
      domain = LoginGov::Hostdata.domain
      "https://dashboard.#{env}.#{domain}/api/service_providers"
    else
      'http://localhost:3001/api/service_providers'
    end
  end

  def default_logger
    logger = Logger.new(STDOUT)
    logger.progname = 'import_logos_to_active_storage'
    logger
  end
end
# rubocop:enable Metrics/ClassLength

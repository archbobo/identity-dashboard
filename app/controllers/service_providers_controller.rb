# rubocop:disable Metrics/ClassLength
class ServiceProvidersController < AuthenticatedController
  before_action :authorize_service_provider
  before_action :authorize_approval, only: [:update]

  def index; end

  # rubocop:disable Metrics/AbcSize
  def create
    @service_provider = ServiceProvider.new(service_provider_params)
    service_provider.agency_id &&= service_provider.agency.id
    service_provider.user = current_user
    service_provider.logo_file.attach(logo_file_param) if logo_file_param
    validate_and_save_service_provider(:new)
  end
  # rubocop:enable Metrics/AbcSize

  def update
    service_provider.assign_attributes(service_provider_params)
    service_provider.agency_id &&= service_provider.agency.id
    validate_and_save_service_provider(:edit)
  end

  def destroy
    service_provider.destroy
    flash[:success] = I18n.t('notices.service_provider_deleted', issuer: service_provider.issuer)
    redirect_to service_providers_path
  end

  def new
    @service_provider = ServiceProvider.new
  end

  def edit; end

  def show; end

  def all
    return unless current_user.admin?
    @service_providers = ServiceProvider.all.sort_by(&:created_at).reverse
  end

  private

  def authorize_service_provider
    authorize service_provider if %i[update edit show destroy].include?(action_name.to_sym)
    authorize ServiceProvider if action_name == 'all'
  end

  def service_provider
    @service_provider ||= ServiceProvider.find(params[:id])
  end

  def authorize_approval
    return unless params.require(:service_provider).key?(:approved) && !current_user.admin?
    raise Pundit::NotAuthorizedError, I18n.t('errors.not_authorized')
  end

  def validate_and_save_service_provider(initial_action)
    return save_service_provider if service_provider.valid?
    flash[:error] = I18n.t('notices.service_providers_refresh_failed')
    render initial_action
  end

  def save_service_provider
    service_provider.save!
    flash[:success] = I18n.t('notices.service_provider_saved', issuer: service_provider.issuer)
    publish_service_providers
    redirect_to service_provider_path(service_provider)
  end

  def publish_service_providers
    if ServiceProviderUpdater.ping == 200
      flash[:notice] = I18n.t('notices.service_providers_refreshed')
    else
      flash[:error] = I18n.t('notices.service_providers_refresh_failed')
    end
  end

  def notify_users(service_provider, initial_action)
    if initial_action == :new
      notify_users_new_service_provider(service_provider)
    elsif service_provider.recently_approved?
      notify_users_approved_service_provider(service_provider)
    end
  end

  def notify_users_new_service_provider(service_provider)
    UserMailer.admin_new_service_provider(service_provider).deliver_later
    UserMailer.user_new_service_provider(service_provider).deliver_later
  end

  def notify_users_approved_service_provider(service_provider)
    UserMailer.admin_approved_service_provider(service_provider).deliver_later
    UserMailer.user_approved_service_provider(service_provider).deliver_later
  end

  def error_messages
    [[@errors] + [service_provider.errors.full_messages]].flatten.compact.to_sentence
  end

  # rubocop:disable MethodLength
  def service_provider_params
    permit_params = [
      :acs_url,
      :active,
      :agency_id,
      :approved,
      :assertion_consumer_logout_service_url,
      :block_encryption,
      :description,
      :friendly_name,
      :group_id,
      :ial,
      :identity_protocol,
      :issuer,
      :logo,
      :metadata_url,
      :return_to_sp_url,
      :failure_to_proof_url,
      :push_notification_url,
      :saml_client_cert,
      :sp_initiated_login_url,
      :logo_file,
      :environment,
      attribute_bundle: [],
      redirect_uris: [],
      help_text: {},
    ]
    permit_params << :production_issuer if current_user.admin?
    params.require(:service_provider).permit(*permit_params)
  end
  # rubocop:enable MethodLength

  def logo_file_param
    service_provider_params[:logo_file]
  end

  helper_method :service_provider
end
# rubocop:enable Metrics/ClassLength

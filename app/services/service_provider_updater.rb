class ServiceProviderUpdater
  def self.ping
    resp = HTTParty.post(idp_url, headers: token_header)
    status_code = resp.code
    return status_code if status_code == 200

    failure = StandardError.new "ServiceProviderUpdater failed with status: #{status_code}"
    handle_error(failure)
    status_code
  rescue StandardError => error
    handle_error(error)
    status_code
  end

  class <<self
    def idp_url
      Figaro.env.idp_sp_url
    end

    def token_header
      { 'X-LOGIN-DASHBOARD-TOKEN' => Figaro.env.dashboard_api_token }
    end

    def handle_error(error)
      ::NewRelic::Agent.notice_error(error)
    end
  end
end

SecureHeaders::Configuration.default do |config|
  config.hsts = "max-age=#{1.day.to_i}; includeSubDomains"
  config.x_frame_options = 'SAMEORIGIN'
  config.x_content_type_options = 'nosniff'
  config.x_xss_protection = '1; mode=block'
  config.x_download_options = 'noopen'
  config.x_permitted_cross_domain_policies = 'none'
  form_action =  ["'self'", '*.identitysandbox.gov']
  form_action << %w[localhost:3000] if Rails.env.development?
  connect_src = ["'self'"]
  connect_src << %w[ws://localhost:3036 http://localhost:3036] if Rails.env.development?
  config.csp = {
    default_src: ["'self'"],
    frame_src: ["'self'"], # deprecated in CSP 2.0
    child_src: ["'self'"], # CSP 2.0 only; replaces frame_src
    # frame_ancestors: %w('self'), # CSP 2.0 only; overriden by x_frame_options in some browsers
    form_action: form_action.flatten,
    block_all_mixed_content: true, # CSP 2.0 only;
    connect_src: connect_src.flatten,
    font_src: ["'self'", 'data:'],
    img_src: ["'self'", 'data:'],
    media_src: ["'self'"],
    object_src: ["'none'"],
    script_src: ["'self'", '*.newrelic.com', '*.nr-data.net'],
    style_src: ["'self'"],
    base_uri: ["'self'"],
  }
  # Temporarily disabled until we configure pinning. See GitHub issue #1895.
  # config.hpkp = {
  #   report_only: false,
  #   max_age: 60.days.to_i,
  #   include_subdomains: true,
  #   pins: [
  #     { sha256: 'abc' },
  #     { sha256: '123' }
  #   ]
  # }
end

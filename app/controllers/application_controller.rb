class ApplicationController < ActionController::Base
  include Pundit

  before_action :set_paper_trail_whodunnit
  before_action :set_requested_url

  protect_from_forgery with: :exception

  rescue_from Pundit::NotAuthorizedError, with: :render_401

  def new_session_path(_scope)
    root_url
  end

  def render_401
    render file: 'public/401.html', status: :unauthorized
  end

  def user_for_paper_trail
    current_user&.email
  end

  private

  def set_requested_url
    return if session[:requested_url]
    session[:requested_url] = request.original_url
  end
end

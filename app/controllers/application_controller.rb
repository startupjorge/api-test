class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :require_login

  helper_method :logged_in?, :employee?, :current_api_key, :current_user_email

  private

  def require_login
    if session_expired?
      reset_session
      redirect_to login_path, alert: "Your access link has expired. Ask your Gumshoe contact for a new one." and return
    end
    redirect_to login_path unless logged_in?
  end

  def session_expired?
    return false if session[:session_expires_at].blank?
    Time.parse(session[:session_expires_at]) < Time.current
  rescue
    false
  end

  def require_api_key
    return if current_api_key.present?
    redirect_to settings_path, alert: "Set your Gumshoe API key to continue."
  end

  def require_employee
    redirect_to root_path unless employee?
  end

  def logged_in?
    session[:employee_email].present? || session[:customer_email].present?
  end

  def employee?
    session[:employee_email].present?
  end

  def current_user_email
    session[:employee_email] || session[:customer_email]
  end

  def current_api_key
    session[:api_key]
  end

  def gumshoe_pagination_params
    params.permit(:limit, :sort, :token).to_h.compact_blank
  end

  def set_gumshoe_pagination(parsed)
    return unless parsed.is_a?(Hash)
    @pagination_meta = parsed["meta"] || parsed[:meta]
    links = parsed["links"] || parsed[:links] || {}
    @next_token = gumshoe_token_from_link(links["next"] || links[:next])
    @prev_token = gumshoe_token_from_link(links["prev"] || links[:prev])
  end

  def gumshoe_token_from_link(link)
    return if link.blank?
    Rack::Utils.parse_query(URI.parse(link).query)["token"]
  rescue URI::InvalidURIError
    nil
  end
end

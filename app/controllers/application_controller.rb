class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :require_login

  helper_method :logged_in?, :employee?, :current_api_key, :current_user_email

  private

  def require_login
    redirect_to login_path unless logged_in?
  end

  def require_employee
    redirect_to root_path unless employee?
  end

  def logged_in?
    session[:api_key].present?
  end

  def employee?
    email = session[:user_email].to_s
    email.present? && email.end_with?("@gumshoe.ai")
  end

  def current_user_email
    session[:user_email]
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

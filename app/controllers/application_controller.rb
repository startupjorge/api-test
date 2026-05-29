class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :require_login

  helper_method :current_employee, :logged_in?

  private

  def require_login
    redirect_to login_path unless logged_in?
  end

  def logged_in?
    session[:employee_email].present?
  end

  def current_employee
    session[:employee_email]
  end

  def current_api_key
    session[:gumshoe_api_key].presence ||
      ENV["GUMSHOE_API_KEY"].presence ||
      Rails.application.credentials.dig(:gumshoe, :api_key)
  rescue
    nil
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

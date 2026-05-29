class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :require_login

  helper_method :current_employee, :current_customer, :logged_in?, :employee?, :current_api_key

  private

  def require_login
    redirect_to login_path unless logged_in?
  end

  def require_employee
    redirect_to login_path unless employee?
  end

  def logged_in?
    session[:employee_email].present? || session[:customer_email].present?
  end

  def employee?
    session[:employee_email].present?
  end

  def current_employee
    session[:employee_email]
  end

  def current_customer
    session[:customer_email]
  end

  def current_user_email
    current_employee || current_customer
  end

  def current_api_key
    if current_customer
      session[:gumshoe_api_key].presence
    else
      session[:gumshoe_api_key].presence ||
        ENV["GUMSHOE_API_KEY"].presence ||
        Rails.application.credentials.dig(:gumshoe, :api_key)
    end
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

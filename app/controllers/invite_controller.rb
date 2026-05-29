class InviteController < ApplicationController
  before_action :require_employee

  def index
    @customers      = Customer.order(:email) rescue []
    @custom_queries = CustomQuery.active.order(:name) rescue []
    load_reports_for_deeplink
  rescue => e
    @customers      ||= []
    @custom_queries ||= []
    @deeplink_reports ||= []
    flash.now[:alert] = "Could not load page: #{e.message}"
  end

  def create
    email   = params[:email].to_s.strip.downcase
    api_key = params[:api_key].to_s.strip.presence

    if email.blank?
      @customers = Customer.order(:email) rescue []
      @custom_queries = CustomQuery.active.order(:name)
      load_reports_for_deeplink
      flash.now[:alert] = "Please enter a customer email."
      render :index, status: :unprocessable_entity and return
    end

    expiry, @expires_label = case params[:expires_in]
    when "1_day"   then [1.day,    "Expires in 24 hours"]
    when "7_days"  then [7.days,   "Expires in 7 days"]
    when "30_days" then [30.days,  "Expires in 30 days"]
    when "90_days" then [90.days,  "Expires in 90 days"]
    when "1_year"  then [1.year,   "Expires in 1 year"]
    when "never"   then [nil,      "Does not expire"]
    else                [30.days,  "Expires in 30 days"]
    end

    # Build optional deep-link redirect path
    report_id  = params[:report_id].presence
    query_type = params[:query_type].presence
    redirect_to_path = if report_id.present?
      path = "/reports/#{report_id}"
      path += "?query_type=#{query_type}" if query_type.present?
      path
    end

    token_data = { email: email, api_key: api_key }
    token_data[:redirect_to] = redirect_to_path if redirect_to_path.present?

    token = if expiry
      Rails.application.message_verifier(:access).generate(token_data, expires_in: expiry)
    else
      Rails.application.message_verifier(:access).generate(token_data)
    end

    customer = Customer.find_or_initialize_by(email: email)
    customer.api_key           = api_key if api_key.present?
    customer.invite_token      = token
    customer.invite_expires_at = expiry ? Time.current + expiry : nil
    customer.save!

    @access_link   = access_link_url(token)
    @invited_email = email
    @deep_link_report_id  = report_id
    @deep_link_query_type = query_type
    @customers      = Customer.order(:email)
    @custom_queries = CustomQuery.active.order(:name)
    load_reports_for_deeplink
    render :index
  rescue => e
    @customers      = Customer.order(:email) rescue []
    @custom_queries = CustomQuery.active.order(:name) rescue []
    load_reports_for_deeplink rescue nil
    @deeplink_reports ||= []
    flash.now[:alert] = "Error: #{e.message}"
    render :index, status: :unprocessable_entity
  end

  private

  def load_reports_for_deeplink
    return unless current_api_key.present?
    client = GumshoeClient.new(current_api_key)
    response = client.reports
    if response.success?
      parsed = response.parsed_response
      @deeplink_reports = if parsed.is_a?(Hash)
        parsed["data"] || parsed[:data] || parsed["reports"] || []
      elsif parsed.is_a?(Array)
        parsed
      else
        []
      end
    else
      @deeplink_reports = []
    end
  rescue
    @deeplink_reports = []
  end
end

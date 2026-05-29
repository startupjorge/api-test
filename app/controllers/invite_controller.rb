class InviteController < ApplicationController
  before_action :require_employee

  def index
    @customers = Customer.order(:email)
  rescue => e
    @customers = []
    flash.now[:alert] = "Could not load customer list: #{e.message}"
  end

  def create
    email   = params[:email].to_s.strip.downcase
    api_key = params[:api_key].to_s.strip.presence

    if email.blank?
      @customers = Customer.order(:email) rescue []
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

    token = if expiry
      Rails.application.message_verifier(:access).generate(
        { email: email, api_key: api_key },
        expires_in: expiry
      )
    else
      Rails.application.message_verifier(:access).generate(
        { email: email, api_key: api_key }
      )
    end

    customer = Customer.find_or_initialize_by(email: email)
    customer.api_key           = api_key if api_key.present?
    customer.invite_token      = token
    customer.invite_expires_at = expiry ? Time.current + expiry : nil
    customer.save!

    @access_link   = access_link_url(token)
    @invited_email = email
    @customers     = Customer.order(:email)
    render :index
  rescue => e
    @customers = Customer.order(:email) rescue []
    flash.now[:alert] = "Error: #{e.message}"
    render :index, status: :unprocessable_entity
  end
end

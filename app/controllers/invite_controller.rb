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

    customer = Customer.find_or_initialize_by(email: email)
    customer.api_key = api_key if api_key.present?
    customer.save!

    token = Rails.application.message_verifier(:access).generate(
      { email: email, api_key: api_key },
      expires_in: 90.days
    )

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

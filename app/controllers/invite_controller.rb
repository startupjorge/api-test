class InviteController < ApplicationController
  before_action :require_employee

  def index
  end

  def create
    email   = params[:email].to_s.strip.downcase
    api_key = params[:api_key].to_s.strip.presence

    if email.blank?
      flash.now[:alert] = "Please enter a customer email."
      render :index, status: :unprocessable_entity and return
    end

    token = Rails.application.message_verifier(:access).generate(
      { email: email, api_key: api_key },
      expires_in: 90.days
    )

    @access_link   = access_link_url(token)
    @invited_email = email
    render :index
  end
end

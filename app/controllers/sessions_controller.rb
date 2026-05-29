class SessionsController < ApplicationController
  skip_before_action :require_login

  def new
    redirect_to root_path if logged_in?
  end

  def create
    email = params[:email].to_s.strip.downcase
    name  = email.split("@").first.capitalize

    if email.end_with?("@gumshoe.ai") && email.length > "@gumshoe.ai".length
      session[:employee_email] = email
      session.delete(:customer_email)
      redirect_to current_api_key.present? ? root_path : settings_path,
                  notice: "Welcome, #{name}!"
    elsif CustomerAccess.allowed?(email)
      session[:customer_email] = email
      session.delete(:employee_email)
      assigned_key = CustomerAccess.api_key_for(email)
      session[:api_key] = assigned_key if assigned_key.present?
      redirect_to current_api_key.present? ? root_path : settings_path,
                  notice: "Welcome, #{name}!"
    else
      flash.now[:alert] = "That email isn't on the access list. Ask your Gumshoe contact to add you."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to login_path
  end

  # Access via shared invite link
  def access
    data = Rails.application.message_verifier(:access).verify(params[:token])
    session[:api_key]        = data[:api_key]    if data[:api_key].present?
    session[:customer_email] = data[:email]      if data[:email].present?

    # Store expiry in session so access is revoked when link expires
    customer = Customer.find_by(email: data[:email]) if data[:email].present?
    if customer&.invite_expires_at.present?
      session[:session_expires_at] = customer.invite_expires_at.iso8601
    end

    if session[:customer_email].present? || session[:api_key].present?
      redirect_to root_path, notice: "Welcome! You're now viewing the Gumshoe API."
    else
      redirect_to login_path, notice: "Access link accepted — enter your email to continue."
    end
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to login_path, alert: "This access link is invalid or has expired."
  end
end

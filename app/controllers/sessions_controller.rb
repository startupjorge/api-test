class SessionsController < ApplicationController
  skip_before_action :require_login

  def new
    redirect_to root_path if logged_in?
  end

  def create
    api_key = params[:api_key].to_s.strip
    if api_key.blank?
      flash.now[:alert] = "Please enter your API key."
      render :new, status: :unprocessable_entity and return
    end

    session[:api_key] = api_key

    # Try to detect user email from the API
    begin
      client = GumshoeClient.new(api_key)
      response = client.me
      if response&.success?
        parsed = response.parsed_response
        email = parsed.is_a?(Hash) ? (parsed["email"] || parsed.dig("data", "email") || parsed.dig("user", "email")) : nil
        session[:user_email] = email if email.present?
      end
    rescue
      # No profile endpoint available — skip email detection
    end

    redirect_to root_path
  end

  def destroy
    reset_session
    redirect_to login_path
  end

  # Access via shared invite link
  def access
    data = Rails.application.message_verifier(:access).verify(params[:token])
    session[:api_key]     = data[:api_key]    if data[:api_key].present?
    session[:user_email]  = data[:email]      if data[:email].present?

    if session[:api_key].present?
      redirect_to root_path, notice: "Welcome! You're now viewing the Gumshoe API."
    else
      redirect_to login_path, notice: "Access link accepted — enter your Gumshoe API key to continue."
    end
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to login_path, alert: "This access link is invalid or has expired."
  end
end

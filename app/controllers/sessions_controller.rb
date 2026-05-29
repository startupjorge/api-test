class SessionsController < ApplicationController
  skip_before_action :require_login

  def new
  end

  def create
    email = params[:email].to_s.strip.downcase
    name = email.split("@").first.capitalize

    if email.end_with?("@gumshoe.ai") && email.length > "@gumshoe.ai".length
      session[:employee_email] = email
      session.delete(:customer_email)
      if current_api_key.blank?
        redirect_to settings_path, notice: "Welcome, #{name}! Start by adding your Gumshoe API key."
      else
        redirect_to explore_internal_path, notice: "Welcome back, #{name}!"
      end
    elsif CustomerAccess.allowed?(email)
      session[:customer_email] = email
      session.delete(:employee_email)
      assigned_key = CustomerAccess.api_key_for(email)
      session[:gumshoe_api_key] = assigned_key if assigned_key.present?
      if session[:gumshoe_api_key].blank?
        redirect_to settings_path, notice: "Welcome, #{name}! Add your Gumshoe API key to get started."
      else
        redirect_to reports_path, notice: "Welcome, #{name}!"
      end
    else
      flash.now[:alert] = "That email isn't on the access list. Ask your Gumshoe contact to add you."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:employee_email)
    session.delete(:customer_email)
    redirect_to login_path, notice: "You've been signed out."
  end

  def goodbye
    # Handles stale GET /logout links — just sign out and show login
    session.delete(:employee_email)
    session.delete(:customer_email)
    redirect_to login_path, notice: "You've been signed out."
  end
end

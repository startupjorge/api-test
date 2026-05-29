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
      redirect_to explore_customer_path, notice: "Welcome, #{name}!"
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
end

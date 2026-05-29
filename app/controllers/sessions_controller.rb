class SessionsController < ApplicationController
  skip_before_action :require_login

  def new
  end

  def create
    email = params[:email].to_s.strip.downcase
    if email.end_with?("@gumshoe.ai") && email.length > "@gumshoe.ai".length
      session[:employee_email] = email
      name = email.split("@").first.capitalize
      if current_api_key.blank?
        redirect_to settings_path, notice: "Welcome, #{name}! Start by adding your Gumshoe API key."
      else
        redirect_to explore_internal_path, notice: "Welcome back, #{name}!"
      end
    else
      flash.now[:alert] = "Access is limited to @gumshoe.ai email addresses."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:employee_email)
    redirect_to login_path, notice: "You've been signed out."
  end
end

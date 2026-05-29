class SessionsController < ApplicationController
  skip_before_action :require_login

  def new
  end

  def create
    email = params[:email].to_s.strip.downcase
    if email.end_with?("@gumshoe.ai") && email.length > "@gumshoe.ai".length
      session[:employee_email] = email
      redirect_to root_path, notice: "Welcome, #{email.split('@').first.capitalize}!"
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

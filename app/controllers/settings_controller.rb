class SettingsController < ApplicationController
  before_action :require_employee

  def show
    @customer_accesses = CustomerAccess.order(:email)
  end

  def update
    key = params[:api_key].to_s.strip
    if key.present?
      session[:gumshoe_api_key] = key
      redirect_to settings_path, notice: "API key saved for this session."
    else
      session.delete(:gumshoe_api_key)
      redirect_to settings_path, notice: "API key cleared."
    end
  end

  def add_customer
    email = params[:email].to_s.strip.downcase
    note = params[:note].to_s.strip
    ca = CustomerAccess.new(email: email, note: note)
    if ca.save
      redirect_to settings_path, notice: "#{email} added. They can now log in."
    else
      redirect_to settings_path, alert: "Could not add: #{ca.errors.full_messages.join(', ')}"
    end
  end

  def remove_customer
    CustomerAccess.find_by(email: params[:email])&.destroy
    redirect_to settings_path, notice: "#{params[:email]} removed."
  end
end

class SettingsController < ApplicationController
  before_action :require_employee

  def show
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
end

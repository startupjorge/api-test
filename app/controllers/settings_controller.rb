class SettingsController < ApplicationController

  def show
  end

  def update
    key = params[:api_key].to_s.strip
    if key.present?
      session[:api_key] = key
      redirect_to settings_path, notice: "API key saved for this session."
    else
      session.delete(:api_key)
      redirect_to settings_path, notice: "API key cleared."
    end
  end
end

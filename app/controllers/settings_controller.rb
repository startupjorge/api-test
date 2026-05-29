class SettingsController < ApplicationController
  def show
  end

  def customer
  end

  def update
    key = params[:api_key].to_s.strip
    if key.present?
      session[:gumshoe_api_key] = key
      if params[:redirect_to_reports] == "1"
        redirect_to reports_path, notice: "Connected! Here are your reports."
      else
        redirect_to settings_path, notice: "API key saved for this session."
      end
    else
      session.delete(:gumshoe_api_key)
      redirect_to settings_path, notice: "API key cleared."
    end
  end
end

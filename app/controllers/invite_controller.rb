class InviteController < ApplicationController
  before_action :require_employee

  def index
    @customers = Customer.order(:email)
    @new_customer = Customer.new
  rescue => e
    @customers = []
    @new_customer = Customer.new
    flash.now[:alert] = "Database not ready yet — #{e.message}"
  end

  def create
    email = params[:email].to_s.strip.downcase
    api_key = params[:api_key].to_s.strip.presence
    customer = Customer.find_or_initialize_by(email: email)
    customer.api_key = api_key if api_key
    if customer.save
      redirect_to invite_index_path, notice: "#{email} added."
    else
      @customers = Customer.order(:email)
      @new_customer = customer
      flash.now[:alert] = customer.errors.full_messages.to_sentence
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    Customer.find(params[:id]).destroy
    redirect_to invite_index_path, notice: "Customer removed."
  end

  def update_key
    customer = Customer.find(params[:id])
    customer.update(api_key: params[:api_key].to_s.strip.presence)
    redirect_to invite_index_path, notice: "API key updated for #{customer.email}."
  end
end

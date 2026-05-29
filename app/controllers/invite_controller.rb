class InviteController < ApplicationController
  before_action :require_employee

  def index
    @customer_accesses = CustomerAccess.order(:email)
  end

  def create
    email = params[:email].to_s.strip.downcase
    note = params[:note].to_s.strip
    ca = CustomerAccess.new(email: email, note: note)
    if ca.save
      redirect_to invite_index_path, notice: "#{email} added. They can now log in."
    else
      redirect_to invite_index_path, alert: "Could not add: #{ca.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    ca = CustomerAccess.find(params[:id])
    email = ca.email
    ca.destroy
    redirect_to invite_index_path, notice: "#{email} removed."
  rescue ActiveRecord::RecordNotFound
    redirect_to invite_index_path, alert: "Customer not found."
  end
end

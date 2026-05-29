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
    CustomerAccess.find_by(email: params[:email])&.destroy
    redirect_to invite_index_path, notice: "#{params[:email]} removed."
  end
end

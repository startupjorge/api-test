class InviteController < ApplicationController
  before_action :require_employee

  def index
    @customer_emails = CustomerAccess.all_emails
  end
end

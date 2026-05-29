class InviteController < ApplicationController
  before_action :require_employee

  def index
    @customers = CustomerAccess.all_with_keys
  end
end

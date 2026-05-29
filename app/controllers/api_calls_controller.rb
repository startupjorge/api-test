class ApiCallsController < ApplicationController
  def index
    @query_history = session[:query_history] || []
  end

  def rank_trends; end
  def not_mentioned; end
end

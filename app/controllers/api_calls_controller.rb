class ApiCallsController < ApplicationController
  def index
    @query_history = session[:query_history] || []
  end
end

class CustomQueriesController < ApplicationController
  before_action :require_employee

  def index
    @custom_queries = CustomQuery.order(:name)
  end

  def new
    @custom_query = CustomQuery.new
  end

  def create
    @custom_query = CustomQuery.new(custom_query_params)
    if @custom_query.save
      redirect_to custom_queries_path, notice: "Query \"#{@custom_query.name}\" added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @custom_query = CustomQuery.find(params[:id])
  end

  def update
    @custom_query = CustomQuery.find(params[:id])
    if @custom_query.update(custom_query_params)
      redirect_to custom_queries_path, notice: "Query updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    CustomQuery.find(params[:id]).destroy
    redirect_to custom_queries_path, notice: "Query removed."
  end

  # JSON proxy — returns reports list from Gumshoe API
  def api_reports
    client = GumshoeClient.new(current_api_key)
    response = client.reports
    parsed = response.parsed_response
    reports = if parsed.is_a?(Hash)
      parsed["data"] || parsed[:data] || parsed["reports"] || []
    elsif parsed.is_a?(Array)
      parsed
    else
      []
    end
    render json: reports
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # JSON proxy — returns latest run data for a report
  def api_sample_run
    report_id = params[:report_id]
    client    = GumshoeClient.new(current_api_key)
    runs      = client.get_runs(report_id)
    latest    = runs.sort_by { |r| (r["ordinal"] || r[:ordinal]).to_i }.last
    unless latest
      render json: { error: "No runs found for this report." }, status: :not_found and return
    end
    ordinal  = latest["ordinal"] || latest[:ordinal]
    response = client.report_run(report_id, ordinal)
    parsed   = response.parsed_response
    data     = parsed.is_a?(Hash) ? (parsed["data"] || parsed) : parsed
    render json: { ordinal: ordinal, data: data }
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def custom_query_params
    params.require(:custom_query).permit(:name, :description, :icon, :query_key, :value_path, :y_axis_label, :active)
  end
end

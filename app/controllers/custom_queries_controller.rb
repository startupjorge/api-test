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

  private

  def custom_query_params
    params.require(:custom_query).permit(:name, :description, :icon, :query_key, :value_path, :y_axis_label, :active)
  end
end

class AddReportIdToCustomQueries < ActiveRecord::Migration[8.0]
  def change
    add_column :custom_queries, :report_id, :string
    add_column :custom_queries, :report_title, :string
  end
end

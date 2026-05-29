CustomQuery.find_or_create_by(query_key: "visibility_score") do |q|
  q.name         = "Visibility Score"
  q.description  = "Overall AI visibility score plotted across all runs"
  q.icon         = "👁️"
  q.value_path   = "scores.overallScore"
  q.y_axis_label = "Score"
  q.active       = true
end

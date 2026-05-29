class ExploreController < ApplicationController

  def internal
    @reports = load_reports_list

    if params[:report_id].present? && params[:query_type].present?
      @report_id  = params[:report_id]
      @query_type = params[:query_type]
      @brand_key  = params[:brand_key].to_s.strip.presence
      @ordinal    = params[:ordinal].presence || "1"

      client = GumshoeClient.new(current_api_key)

      case @query_type
      when "trends"        then build_trends(client)
      when "not_mentioned" then build_not_mentioned(client)
      end

      save_query_to_history(@query_type, @report_id, @brand_key) unless @result_error
    end
  rescue => e
    @result_error = e.message
    Rails.logger.error "ExploreController error: #{e.class} - #{e.message}"
  end

  def customer
    redirect_to root_path
  end

  private

  def load_reports_list
    return [] if current_api_key.blank?
    client = GumshoeClient.new(current_api_key)
    response = client.reports({})
    return [] unless response.success?
    parsed = response.parsed_response
    parsed.is_a?(Hash) ? (parsed["data"] || parsed["reports"] || []) : (parsed || [])
  rescue
    []
  end

  def save_query_to_history(action, report_id, brand_key)
    history = session[:query_history] || []
    history.unshift(
      "action"    => action.to_s,
      "report_id" => report_id,
      "brand_key" => brand_key,
      "ran_at"    => Time.current.iso8601
    )
    session[:query_history] = history.first(50)
  end

  def build_trends(client)
    runs = client.get_runs(@report_id)
    mutex = Mutex.new
    raw_by_ordinal = {}

    threads = runs.map do |run|
      Thread.new do
        ordinal = run["ordinal"] || run[:ordinal]
        raw = client.get_raw(@report_id, ordinal)
        mutex.synchronize { raw_by_ordinal[ordinal] = { run: run, raw: raw } }
      end
    end
    threads.each(&:join)

    brand_series = {}
    run_labels   = {}

    raw_by_ordinal.each do |ordinal, data|
      run = data[:run]
      raw = data[:raw]
      run_labels[ordinal] = run["createdAt"] || run[:created_at] || ordinal.to_s
      brand_counts  = Hash.new(0)
      total_answers = 0

      (raw["personas"] || []).each do |persona|
        (persona["questions"] || []).each do |question|
          (question["answers"] || []).each do |answer|
            total_answers += 1
            (answer["mentions"] || []).each do |mention|
              if (mention["rank"] || mention[:rank]) == 1
                brand = mention["brand"] || mention[:brand] || {}
                bkey  = brand["key"]  || brand[:key]  || "unknown"
                bname = brand["name"] || brand[:name] || bkey
                brand_series[bkey] ||= { name: bname, points: {} }
                brand_counts[bkey] += 1
              end
            end
          end
        end
      end

      brand_series.each_key do |bkey|
        pct = total_answers > 0 ? (brand_counts[bkey].to_f / total_answers * 100).round(1) : 0
        brand_series[bkey][:points][ordinal] = pct
      end
    end

    sorted_ordinals = run_labels.keys.sort
    @chart_labels   = sorted_ordinals.map { |o| run_labels[o] }
    @chart_datasets = brand_series.map do |_key, series|
      { label: series[:name], data: sorted_ordinals.map { |o| series[:points][o] || 0 } }
    end
    @result_type    = :trends
    @api_endpoints  = [
      "GET /reports/#{@report_id}/runs",
      "GET /reports/#{@report_id}/runs/:ordinal/raw  (fetched #{runs.size} runs)"
    ]
  end

  def build_not_mentioned(client)
    unless @brand_key.present?
      @result_error = "Please enter a brand key to check who's not mentioned."
      return
    end

    raw         = client.get_raw(@report_id, @ordinal)
    all_answers = []

    (raw["personas"] || []).each do |persona|
      persona_name = persona["name"] || "Unknown Persona"
      (persona["questions"] || []).each do |question|
        q_text  = question["text"]  || ""
        q_model = question["model"] || ""
        (question["answers"] || []).each do |answer|
          all_answers << {
            persona_name:,
            question_text: q_text,
            model:         q_model,
            answer_text:   answer["text"] || "",
            citations:     answer["citations"] || [],
            mentions:      answer["mentions"]  || []
          }
        end
      end
    end

    @total_answers = all_answers.size
    @not_mentioned = all_answers.reject do |a|
      a[:mentions].any? do |m|
        (m["brand"] || m[:brand] || {}).values_at("key", :key).compact.any? { |k| k == @brand_key }
      end
    end
    @result_type   = :not_mentioned
    @api_endpoints = ["GET /reports/#{@report_id}/runs/#{@ordinal}/raw"]
  end
end

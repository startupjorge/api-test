class ExploreController < ApplicationController
  def internal
    process_query if params[:query].present?
  end

  def customer
    process_query if params[:query].present?
  end

  private

  def process_query
    @query = params[:query].to_s.strip
    @intent = detect_intent(@query)
    return if @intent[:action] == :unknown

    client = GumshoeClient.new(current_api_key)

    case @intent[:action]
    when :trends        then build_trends(client)
    when :not_mentioned then build_not_mentioned(client)
    when :list_reports  then build_reports_list(client)
    when :show_report   then build_report(client)
    end
  rescue => e
    @result_error = e.message
    Rails.logger.error "ExploreController error: #{e.class} - #{e.message}"
  end

  def detect_intent(query)
    q = query.downcase

    # Extract report ID — handles "22110", "rpt_abc", "report 22110"
    report_id =
      q.match(/\b(rpt_[a-z0-9_]+)\b/)&.[](1) ||
      q.match(/report\s+#?([a-z0-9_]+)/i)&.[](1) ||
      q.match(/\b(\d{4,6})\b/)&.[](1)

    # Extract run ordinal
    ordinal =
      q.match(/run\s+#?(\d+)/i)&.[](1) ||
      q.match(/ordinal\s+(\d+)/i)&.[](1) || "1"

    # Extract brand key — word following common cues
    brand_key =
      q.match(/(?:for brand|brand[:\s]+|brand key[:\s]+)([a-z0-9_-]+)/i)&.[](1) ||
      q.match(/(?:not mentioned|missing|absent)\s+(?:for\s+)?([a-z0-9_-]+)/i)&.[](1) ||
      q.match(/brand[:\s]+([a-z0-9_-]+)/i)&.[](1)

    action =
      if q =~ /trend|rank over|over time|chart|ranking over|how.*rank|ranked.*over/
        :trends
      elsif q =~ /not mention|missing|absent|gap|never|without.*mention/
        :not_mentioned
      elsif q =~ /list|show all|all report|my report/
        :list_reports
      elsif report_id
        :show_report
      else
        :unknown
      end

    { action:, report_id:, ordinal:, brand_key: }
  end

  def build_trends(client)
    unless @intent[:report_id]
      @result_error = "Please include a report ID — e.g. \"rank trends for report 22110\""
      return
    end
    @result_type = :trends
    @report_id = @intent[:report_id]

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
    run_labels = {}

    raw_by_ordinal.each do |ordinal, data|
      run = data[:run]
      raw = data[:raw]
      run_labels[ordinal] = run["createdAt"] || run[:created_at] || ordinal.to_s
      brand_counts = Hash.new(0)
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
  end

  def build_not_mentioned(client)
    unless @intent[:report_id]
      @result_error = "Please include a report ID — e.g. \"not mentioned for shipiumcom in report 22110 run 1\""
      return
    end
    unless @intent[:brand_key]
      @result_error = "Please include a brand key — e.g. \"not mentioned for brand shipiumcom in report 22110\""
      return
    end

    @result_type = :not_mentioned
    @report_id = @intent[:report_id]
    @ordinal   = @intent[:ordinal]
    @brand_key = @intent[:brand_key]

    raw = client.get_raw(@report_id, @ordinal)
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
            model: q_model,
            answer_text: answer["text"] || "",
            citations: answer["citations"] || [],
            mentions:  answer["mentions"]  || []
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
  end

  def build_reports_list(client)
    @result_type = :reports
    response = client.reports({})
    if response.success?
      parsed = response.parsed_response
      @reports = parsed.is_a?(Hash) ? (parsed["data"] || parsed["reports"] || []) : parsed
    else
      @result_error = "Failed to fetch reports: HTTP #{response.code}"
    end
  end

  def build_report(client)
    @result_type = :report
    @report_id = @intent[:report_id]
    response = client.report(@report_id)
    if response.success?
      parsed = response.parsed_response
      @report = parsed.is_a?(Hash) ? (parsed["data"] || parsed["report"] || parsed) : parsed
    else
      @result_error = "Failed to fetch report: HTTP #{response.code}"
    end
  end
end

class ReportsController < ApplicationController
  include GumshoeApiUrls

  def index
    @curl_command = curl_command(reports_url)

    begin
      api_key = current_api_key
      @curl_command = curl_command(reports_url)
      client = GumshoeClient.new(api_key)
      response = client.reports(gumshoe_pagination_params)
      @curl_command = client.curl_command

      if response.success?
        parsed = response.parsed_response
        set_gumshoe_pagination(parsed)
        @reports = if parsed.is_a?(Hash) && parsed["data"]
          parsed["data"]
        elsif parsed.is_a?(Hash) && parsed[:data]
          parsed[:data]
        elsif parsed.is_a?(Hash) && parsed["reports"]
          parsed["reports"]
        elsif parsed.is_a?(Hash) && parsed[:reports]
          parsed[:reports]
        elsif parsed.is_a?(Array)
          parsed
        else
          [ parsed ]
        end
      else
        @reports = []
        @error = "Failed to fetch reports: HTTP #{response.code} - #{response.message}"
      end
    rescue => e
      @reports = []
      @error = "Error fetching reports: #{e.class} - #{e.message}"
      Rails.logger.error "Exception: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}"
    end
  end

  def show
    client = GumshoeClient.new(current_api_key)
    response = client.report(params[:id])

    unless response.success?
      redirect_to reports_path, alert: "Failed to load report." and return
    end

    parsed = response.parsed_response
    @report = parsed.is_a?(Hash) ? (parsed["data"] || parsed["report"] || parsed) : parsed
    @report_id = params[:id]
    brand = @report.is_a?(Hash) ? (@report["brand"] || @report[:brand] || {}) : {}
    @brand_key = brand["key"] || brand[:key]
    @brand_name = brand["name"] || brand[:name]

    @query_type = params[:query_type]

    case @query_type
    when "trends"
      build_trends_data
    when "not_mentioned"
      @brand_key = params[:brand_key].presence || @brand_key
      @ordinal   = params[:ordinal].presence || "1"
      build_not_mentioned_data(client)
    end
  rescue => e
    redirect_to reports_path, alert: e.message
  end

  def trends
    build_trends_data
  end


  private

  def build_not_mentioned_data(client)
    raw = client.get_raw(@report_id, @ordinal)
    all_answers = []

    (raw["personas"] || []).each do |persona|
      persona_name = persona["name"] || "Unknown Persona"
      (persona["questions"] || []).each do |question|
        q_text  = question["text"]  || ""
        q_model = question["model"] || ""
        (question["answers"] || []).each do |answer|
          all_answers << {
            persona_name: persona_name,
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
      a[:mentions].any? { |m| (m["brand"] || m[:brand] || {}).values_at("key", :key).compact.any? { |k| k == @brand_key } }
    end
  rescue => e
    @error = "Error loading data: #{e.message}"
    @not_mentioned = []
    @total_answers  = 0
  end

  def compute_run_stats(client, report_id, ordinal)
    raw = client.get_raw(report_id, ordinal)
    brand_counts = Hash.new(0)
    not_mentioned_counts = Hash.new(0)
    brand_names = {}
    total = 0

    (raw["personas"] || []).each do |persona|
      (persona["questions"] || []).each do |question|
        (question["answers"] || []).each do |answer|
          total += 1
          mentioned = {}
          (answer["mentions"] || []).each do |m|
            b = m["brand"] || m[:brand] || {}
            bkey = b["key"] || b[:key] || "unknown"
            bname = b["name"] || b[:name] || bkey
            brand_names[bkey] = bname
            mentioned[bkey] = true
            brand_counts[bkey] += 1 if (m["rank"] || m[:rank]) == 1
          end
          brand_names.each_key { |bkey| not_mentioned_counts[bkey] += 1 unless mentioned[bkey] }
        end
      end
    end

    { total: total, brand_counts: brand_counts, not_mentioned_counts: not_mentioned_counts, brand_names: brand_names }
  rescue => e
    Rails.logger.warn "compute_run_stats failed: #{e.message}"
    nil
  end

  def build_trends_data
    begin
      client = GumshoeClient.new(current_api_key)
      runs = client.get_runs(params[:id])

      mutex = Mutex.new
      raw_by_ordinal = {}

      threads = runs.map do |run|
        Thread.new do
          ordinal = run["ordinal"] || run[:ordinal]
          raw = client.get_raw(params[:id], ordinal)
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
                  bkey = brand["key"] || brand[:key] || "unknown"
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
      @chart_labels = sorted_ordinals.map { |o| run_labels[o] }
      @chart_datasets = brand_series.map do |_key, series|
        { label: series[:name], data: sorted_ordinals.map { |o| series[:points][o] || 0 } }
      end
      @report_id = params[:id]
    rescue => e
      @error = "Error building trends: #{e.message}"
      Rails.logger.error "#{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    end
  end
end

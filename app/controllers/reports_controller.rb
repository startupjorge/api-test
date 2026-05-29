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
    begin
      client = GumshoeClient.new(current_api_key)
      response = client.report(params[:id])
      @curl_command = client.curl_command

      if response.success?
        parsed = response.parsed_response
        @report = if parsed.is_a?(Hash) && parsed["data"]
          parsed["data"]
        elsif parsed.is_a?(Hash) && parsed[:data]
          parsed[:data]
        elsif parsed.is_a?(Hash) && parsed["report"]
          parsed["report"]
        elsif parsed.is_a?(Hash) && parsed[:report]
          parsed[:report]
        else
          parsed
        end
        @runs = @report.is_a?(Hash) ? (@report["runs"] || @report[:runs] || []) : []
        latest_run = @runs.max_by { |r| (r["ordinal"] || r[:ordinal] || 0).to_i }
        if latest_run
          latest_ordinal = latest_run["ordinal"] || latest_run[:ordinal]
          @latest_stats = compute_run_stats(client, params[:id], latest_ordinal)
          @latest_ordinal = latest_ordinal
        end
      else
        @error = "Failed to fetch report: HTTP #{response.code} - #{response.message}"
        redirect_to reports_path, alert: @error
      end
    rescue => e
      @error = "Error fetching report: #{e.message}"
      redirect_to reports_path, alert: @error
    end
  end

  def trends
    build_trends_data
  end

  def customer_trends
    build_trends_data
  end

  private

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

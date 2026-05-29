class ReportRunsController < ApplicationController
  include GumshoeApiUrls

  before_action :set_report_id

  def index
    @curl_command = curl_command(report_runs_url(@report_id))

    begin
      api_key = current_api_key
      if api_key.blank?
        @error = "No API key set. Please add your API key in Settings."
        @report_runs = []
        return
      end

      client = GumshoeClient.new(api_key)
      response = client.report_runs(@report_id, gumshoe_pagination_params)
      @curl_command = client.curl_command

      if response.success?
        parsed = response.parsed_response
        set_gumshoe_pagination(parsed)
        @report_runs = if parsed.is_a?(Hash) && parsed["data"]
          parsed["data"]
        elsif parsed.is_a?(Hash) && parsed[:data]
          parsed[:data]
        elsif parsed.is_a?(Hash) && parsed["runs"]
          parsed["runs"]
        elsif parsed.is_a?(Hash) && parsed[:runs]
          parsed[:runs]
        elsif parsed.is_a?(Array)
          parsed
        else
          [ parsed ]
        end
      else
        @report_runs = []
        @error = "Failed to fetch report runs: HTTP #{response.code} - #{response.message}"
      end
    rescue => e
      @report_runs = []
      @error = "Error fetching report runs: #{e.class} - #{e.message}"
      Rails.logger.error "Exception: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}"
    end
  end

  def show
    begin
      client = GumshoeClient.new(current_api_key)
      ordinal = params[:ordinal] || params[:id]
      response = client.report_run(@report_id, ordinal)
      @curl_command = client.curl_command

      if response.success?
        @report_run = response.parsed_response
      else
        @error = "Failed to fetch report run: HTTP #{response.code} - #{response.message}"
        redirect_to report_runs_path(report_id: @report_id), alert: @error
      end
    rescue => e
      @error = "Error fetching report run: #{e.message}"
      redirect_to report_runs_path(report_id: @report_id), alert: @error
    end
  end

  def not_mentioned
    build_not_mentioned_data
  end

  def raw
    begin
      client = GumshoeClient.new(current_api_key)
      ordinal = params[:ordinal] || params[:id]
      response = client.report_run_raw(@report_id, ordinal)
      @curl_command = client.curl_command

      if response.success?
        render plain: response.body, content_type: "application/json"
      else
        @error = "Failed to fetch raw report run: HTTP #{response.code} - #{response.message}"
        redirect_to report_run_path(report_id: @report_id, ordinal: ordinal), alert: @error
      end
    rescue => e
      redirect_to report_run_path(report_id: @report_id, ordinal: params[:ordinal] || params[:id]), alert: e.message
    end
  end

  private

  def set_report_id
    @report_id = params[:report_id]
  end

  def build_not_mentioned_data
    @ordinal = params[:ordinal] || params[:id]
    @brand_key = params[:brand_key].to_s.strip

    begin
      client = GumshoeClient.new(current_api_key)
      raw = client.get_raw(@report_id, @ordinal)

      all_answers = []
      (raw["personas"] || []).each do |persona|
        persona_name = persona["name"] || persona[:name] || "Unknown Persona"
        (persona["questions"] || []).each do |question|
          q_text = question["text"] || question[:text] || ""
          q_model = question["model"] || question[:model] || ""
          (question["answers"] || []).each do |answer|
            all_answers << {
              persona_name: persona_name,
              question_text: q_text,
              model: q_model,
              answer_text: answer["text"] || answer[:text] || "",
              citations: answer["citations"] || answer[:citations] || [],
              mentions: answer["mentions"] || answer[:mentions] || []
            }
          end
        end
      end

      @total_answers = all_answers.size
      @not_mentioned = if @brand_key.present?
        all_answers.reject do |a|
          a[:mentions].any? { |m| (m["brand"] || m[:brand] || {}).values_at("key", :key).compact.any? { |k| k == @brand_key } }
        end
      else
        []
      end
    rescue => e
      @error = "Error fetching data: #{e.message}"
      Rails.logger.error "#{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
      @not_mentioned = []
      @total_answers = 0
    end
  end
end

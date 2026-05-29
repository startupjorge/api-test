class HowToController < ApplicationController
  def index
  end

  def customer
  end

  def try_it_live
    @report_id = params[:report_id].to_s.strip
    @ordinal = params[:ordinal].to_s.strip
    @brand_key = params[:brand_key].to_s.strip

    if @report_id.present? && @ordinal.present? && @brand_key.present?
      begin
        api_key = current_api_key
        client = GumshoeClient.new(api_key)
        raw = client.get_raw(@report_id, @ordinal)

        total = 0
        ranked_first = 0
        not_mentioned = 0

        (raw["personas"] || []).each do |persona|
          (persona["questions"] || []).each do |question|
            (question["answers"] || []).each do |answer|
              total += 1
              mentions = answer["mentions"] || answer[:mentions] || []
              brand_keys = mentions.map { |m| (m["brand"] || m[:brand] || {}).values_at("key", :key).compact }.flatten
              ranked_first += 1 if mentions.any? { |m| (m["rank"] || m[:rank]) == 1 && brand_keys.include?(@brand_key) }
              not_mentioned += 1 unless brand_keys.include?(@brand_key)
            end
          end
        end

        @results = { total: total, ranked_first: ranked_first, not_mentioned: not_mentioned }
      rescue => e
        @error = "Error: #{e.message}"
      end
    end

    render partial: "try_it_live_result"
  end
end

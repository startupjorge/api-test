require "httparty"

class GumshoeClient
  include HTTParty
  include GumshoeApiUrls

  def initialize(api_key)
    @api_key   = api_key
    @base_uri  = GumshoeApiUrls.base_uri
    self.class.base_uri @base_uri
    @headers   = {
      "Authorization" => "Bearer #{api_key}",
      "Content-Type"  => "application/json"
    }
    @api_calls = []
  end

  attr_reader :api_calls

  def curl_command
    @api_calls.last&.dig(:curl)
  end

  def me
    make_request(GumshoeApiUrls.me_url)
  end

  def reports(query = {})
    make_request(GumshoeApiUrls.reports_url, query)
  end

  def report(id)
    make_request(GumshoeApiUrls.report_url(id))
  end

  def report_runs(report_id, query = {})
    make_request(GumshoeApiUrls.report_runs_url(report_id), query)
  end

  def report_run(report_id, ordinal)
    make_request(GumshoeApiUrls.report_run_url(report_id, ordinal))
  end

  def report_run_raw(report_id, ordinal)
    make_request(GumshoeApiUrls.report_run_raw_url(report_id, ordinal))
  end

  # Convenience — raises on error, returns parsed array.
  def get_runs(report_id)
    response = report_runs(report_id)
    raise "Gumshoe API error #{response.code}: #{response.message}" unless response.success?
    parsed = response.parsed_response
    parsed.is_a?(Hash) ? (parsed["data"] || parsed[:data] || parsed["runs"] || []) : (parsed || [])
  end

  # Convenience — raises on error, returns parsed hash. Bypasses cache so test center always shows a real call.
  def get_raw(report_id, ordinal)
    response = report_run_raw(report_id, ordinal)
    raise "Gumshoe API error #{response.code}: #{response.message}" unless response.success?
    response.parsed_response
  end

  private

  def make_request(path, query = {})
    cleaned = query.reject { |_, v| v.blank? }
    opts    = cleaned.any? ? { headers: @headers, query: cleaned } : { headers: @headers }

    t0       = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    response = self.class.get(path, opts)
    elapsed  = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0) * 1000).round

    @api_calls << {
      method:  "GET",
      url:     GumshoeApiUrls.full_url(path, cleaned),
      curl:    GumshoeApiUrls.curl_command(path, cleaned),
      status:  response.code,
      time_ms: elapsed,
      body:    pretty_json(response.body)
    }

    Rails.logger.error "Gumshoe API Error: #{path} - HTTP #{response.code}" if response.code >= 400
    response
  end

  def pretty_json(body)
    JSON.pretty_generate(JSON.parse(body))
  rescue
    body.to_s
  end
end

require "httparty"

class GumshoeClient
  include HTTParty
  include GumshoeApiUrls

  def initialize(api_key)
    @api_key = api_key
    @curl_command = nil
    @base_uri = GumshoeApiUrls.base_uri
    self.class.base_uri @base_uri
    @options = {
      headers: {
        "Authorization" => "Bearer #{api_key}",
        "Content-Type" => "application/json"
      }
    }
  end

  attr_reader :curl_command

  def reports(query = {})
    url = reports_url
    log_request(url, query)
    response = self.class.get(url, request_options(query))
    log_response(response, url)
    response
  end

  def report(id)
    url = report_url(id)
    log_request(url)
    response = self.class.get(url, @options)
    log_response(response, url)
    response
  end

  def report_runs(report_id, query = {})
    url = report_runs_url(report_id)
    log_request(url, query)
    response = self.class.get(url, request_options(query))
    log_response(response, url)
    response
  end

  def report_run(report_id, ordinal)
    url = report_run_url(report_id, ordinal)
    log_request(url)
    response = self.class.get(url, @options)
    log_response(response, url)
    response
  end

  def report_run_raw(report_id, ordinal)
    url = report_run_raw_url(report_id, ordinal)
    log_request(url)
    response = self.class.get(url, @options)
    log_response(response, url)
    response
  end

  # Returns parsed array of runs or raises on error.
  def get_runs(report_id)
    response = report_runs(report_id)
    raise "Gumshoe API error #{response.code}: #{response.message}" unless response.success?

    parsed = response.parsed_response
    if parsed.is_a?(Hash)
      parsed["data"] || parsed[:data] || parsed["runs"] || parsed[:runs] || []
    elsif parsed.is_a?(Array)
      parsed
    else
      []
    end
  end

  # Returns parsed raw hash, cached for 10 minutes.
  def get_raw(report_id, ordinal)
    cache_key = "gumshoe/raw/#{report_id}/#{ordinal}"
    Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
      response = report_run_raw(report_id, ordinal)
      raise "Gumshoe API error #{response.code}: #{response.message}" unless response.success?

      response.parsed_response
    end
  end

  private

  def request_options(query = {})
    cleaned_query = query.reject { |_key, value| value.blank? }
    cleaned_query.any? ? @options.merge(query: cleaned_query) : @options
  end

  def log_request(url, query = {})
    @curl_command = GumshoeApiUrls.curl_command(url, query)
  end

  def log_response(response, url)
    # Only log errors
    if response.code >= 400
      complete_url = GumshoeApiUrls.full_url(url)
      Rails.logger.error "Gumshoe API Error: #{complete_url} - HTTP #{response.code} - #{response.message}"
      Rails.logger.error "Response body: #{response.body}"
    end
  end
end

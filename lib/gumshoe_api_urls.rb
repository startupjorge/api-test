require "uri"

module GumshoeApiUrls
  API_VERSION = "v1"

  module_function

  def base_uri
    @base_uri ||= ENV.fetch("GUMSHOE_API_URL", "https://app.gumshoe.ai")
  end

  def me_url
    "/#{API_VERSION}/me"
  end

  def reports_url
    "/#{API_VERSION}/reports"
  end

  def report_url(id)
    "/#{API_VERSION}/reports/#{id}"
  end

  def report_runs_url(report_id)
    "/#{API_VERSION}/reports/#{report_id}/runs"
  end

  def report_run_url(report_id, ordinal)
    "/#{API_VERSION}/reports/#{report_id}/runs/#{ordinal}"
  end

  def report_run_raw_url(report_id, ordinal)
    "/#{API_VERSION}/reports/#{report_id}/runs/#{ordinal}/raw"
  end

  def full_url(path, query = {})
    url = "#{base_uri}#{path}"
    cleaned_query = query.reject { |_key, value| value.blank? }
    return url if cleaned_query.empty?

    "#{url}?#{URI.encode_www_form(cleaned_query)}"
  end

  def curl_command(path, query = {})
    full = full_url(path, query)
    "curl -X GET '#{full}' -H 'Authorization: Bearer <GUMSHOE_API_KEY>' -H 'Content-Type: application/json' -v"
  end
end

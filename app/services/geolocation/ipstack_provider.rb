require "net/http"
require "json"

module Geolocation
  class IpstackProvider < Provider
    BASE_URL = "http://api.ipstack.com".freeze
    DEFAULT_TIMEOUT = 5 # seconds

    def initialize(api_key: ENV["IPSTACK_API_KEY"], timeout: DEFAULT_TIMEOUT)
      @api_key = api_key
      @timeout = timeout
    end

    # @param ip [String] a valid IP address
    # @return [Hash] normalized geolocation attributes
    # @raise [ProviderError] if ipstack errors, times out, or is unreachable
    def fetch(ip)
      raise ProviderError, "ipstack API key is not configured" if @api_key.to_s.empty?

      body = get(ip)
      data = JSON.parse(body)

      if data["success"] == false
        message = data.dig("error", "info") || "ipstack request failed"
        raise ProviderError, message
      end

      normalize(data)
    rescue JSON::ParserError
      raise ProviderError, "ipstack returned an invalid response"
    rescue Net::OpenTimeout, Net::ReadTimeout, Timeout::Error
      raise ProviderError, "ipstack request timed out"
    rescue SocketError, Errno::ECONNREFUSED => e
      raise ProviderError, "ipstack is unreachable: #{e.message}"
    end

    private

    def get(ip)
      uri = URI("#{BASE_URL}/#{ip}")
      uri.query = URI.encode_www_form(access_key: @api_key)

      Net::HTTP.start(uri.host, uri.port, open_timeout: @timeout, read_timeout: @timeout) do |http|
        http.get(uri.request_uri).body
      end
    end

    # Translate ipstack's payload into the app's canonical shape. Only the
    # fields the app stores are kept; provider-specific extras are dropped.
    def normalize(data)
      {
        ip:             data["ip"],
        ip_type:        data["type"],
        continent_name: data["continent_name"],
        country_name:   data["country_name"],
        country_code:   data["country_code"],
        region_name:    data["region_name"],
        city:           data["city"],
        zip:            data["zip"],
        latitude:       data["latitude"],
        longitude:      data["longitude"]
      }
    end
  end
end

require "ipaddr"
require "resolv"

module Geolocation
  class Lookup
    # Raised when the input is neither a valid IP nor a resolvable hostname.
    class InvalidInput < StandardError; end

    # Raised for IPs that cannot be geolocated (private, reserved, loopback).
    class UnsupportedIP < StandardError; end

    def initialize(provider: Geolocation.provider_class.new)
      @provider = provider
    end

    # @param input [String] an IP address or a URL/hostname
    # @return [Hash] normalized geolocation data plus :query and :query_type
    # @raise [InvalidInput] if the input can't be interpreted
    # @raise [UnsupportedIP] if the resolved IP isn't publicly geolocatable
    # @raise [Geolocation::ProviderError] if the provider fails
    def call(input)
      raise InvalidInput, "input can't be blank" if input.to_s.strip.empty?

      query      = input.strip
      query_type = ip_address?(query) ? "ip" : "url"
      ip         = query_type == "ip" ? query : resolve(query)

      ensure_public!(ip)

      @provider.fetch(ip).merge(query: query, query_type: query_type, ip: ip)
    end

    private

    def ip_address?(value)
      IPAddr.new(value)
      true
    rescue IPAddr::InvalidAddressError
      false
    end

    # Resolve a hostname (or full URL) to its first IP via DNS.
    def resolve(input)
      host = host_from(input)
      addresses = Resolv.getaddresses(host)
      raise InvalidInput, "could not resolve '#{input}'" if addresses.empty?

      addresses.first
    end

    # Accept both bare hostnames ("example.com") and full URLs
    # ("https://example.com/path"); extract just the host.
    def host_from(input)
      uri = URI.parse(input)
      uri.host || uri.path.split("/").first
    rescue URI::InvalidURIError
      input
    end

    def ensure_public!(ip)
      addr = IPAddr.new(ip)
      if addr.private? || addr.loopback? || reserved?(addr)
        raise UnsupportedIP, "#{ip} is a private or reserved address and can't be geolocated"
      end
    end

    def reserved?(addr)
      addr.link_local? if addr.respond_to?(:link_local?)
    rescue StandardError
      false
    end
  end
end

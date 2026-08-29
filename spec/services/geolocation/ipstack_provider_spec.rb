require "rails_helper"

RSpec.describe Geolocation::IpstackProvider do
  subject(:provider) { described_class.new(api_key: "test-key") }

  let(:ip) { "8.8.8.8" }
  let(:endpoint) { %r{\Ahttp://api\.ipstack\.com/#{Regexp.escape(ip)}} }

  # A trimmed version of a real ipstack success response.
  let(:success_body) do
    {
      "ip" => "8.8.8.8",
      "type" => "ipv4",
      "continent_name" => "North America",
      "country_code" => "US",
      "country_name" => "United States",
      "region_name" => "California",
      "city" => "Orinda",
      "zip" => "94563",
      "latitude" => 37.8633,
      "longitude" => -122.1909,
      "location" => { "geoname_id" => 7174025 } # extra data we intentionally drop
    }.to_json
  end

  describe "#fetch" do
    context "on a successful response" do
      before do
        stub_request(:get, endpoint).to_return(status: 200, body: success_body)
      end

      it "returns the app's normalized geolocation shape" do
        result = provider.fetch(ip)

        expect(result).to eq(
          ip: "8.8.8.8",
          ip_type: "ipv4",
          continent_name: "North America",
          country_name: "United States",
          country_code: "US",
          region_name: "California",
          city: "Orinda",
          zip: "94563",
          latitude: 37.8633,
          longitude: -122.1909
        )
      end

      it "drops provider-specific fields not in the app's shape" do
        expect(provider.fetch(ip)).not_to have_key(:location)
      end

      it "sends the api key as a query parameter" do
        provider.fetch(ip)
        expect(a_request(:get, endpoint).with(query: hash_including("access_key" => "test-key")))
          .to have_been_made
      end
    end

    context "when ipstack returns an error payload" do
      before do
        body = { "success" => false, "error" => { "info" => "You have exceeded your monthly quota." } }.to_json
        stub_request(:get, endpoint).to_return(status: 200, body: body)
      end

      it "raises a ProviderError with the provider's message" do
        expect { provider.fetch(ip) }
          .to raise_error(Geolocation::ProviderError, /exceeded your monthly quota/)
      end
    end

    context "when the response is not valid JSON" do
      before do
        stub_request(:get, endpoint).to_return(status: 200, body: "<html>not json</html>")
      end

      it "raises a ProviderError" do
        expect { provider.fetch(ip) }
          .to raise_error(Geolocation::ProviderError, /invalid response/)
      end
    end

    context "when the request times out" do
      before { stub_request(:get, endpoint).to_timeout }

      it "raises a ProviderError" do
        expect { provider.fetch(ip) }
          .to raise_error(Geolocation::ProviderError, /timed out|unreachable/)
      end
    end

    context "when the api key is missing" do
      subject(:provider) { described_class.new(api_key: nil) }

      it "raises a ProviderError without making a request" do
        expect { provider.fetch(ip) }
          .to raise_error(Geolocation::ProviderError, /not configured/)
        expect(a_request(:get, endpoint)).not_to have_been_made
      end
    end
  end

  it "is a Geolocation::Provider" do
    expect(provider).to be_a(Geolocation::Provider)
  end
end

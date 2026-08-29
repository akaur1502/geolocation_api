require "rails_helper"

RSpec.describe Geolocation::Lookup do
  # A fake provider so these tests never touch the network and don't depend on
  # ipstack. This is dependency injection in action.
  let(:provider) { instance_double(Geolocation::IpstackProvider) }
  let(:geo_data) { { ip: "8.8.8.8", city: "Mountain View", country_name: "United States" } }

  subject(:lookup) { described_class.new(provider: provider) }

  describe "#call" do
    context "with a public IPv4 address" do
      it "detects the input as an IP and delegates to the provider" do
        allow(provider).to receive(:fetch).with("8.8.8.8").and_return(geo_data)

        result = lookup.call("8.8.8.8")

        expect(result[:query]).to eq("8.8.8.8")
        expect(result[:query_type]).to eq("ip")
        expect(result[:ip]).to eq("8.8.8.8")
        expect(result[:city]).to eq("Mountain View")
      end
    end

    context "with a public IPv6 address" do
      it "accepts it and delegates to the provider" do
        ipv6 = "2001:4860:4860::8888"
        allow(provider).to receive(:fetch).with(ipv6).and_return(geo_data.merge(ip: ipv6))

        result = lookup.call(ipv6)

        expect(result[:query_type]).to eq("ip")
        expect(result[:ip]).to eq(ipv6)
      end
    end

    context "with a URL" do
      before do
        # Stub DNS resolution so the test is deterministic.
        allow(Resolv).to receive(:getaddresses).with("example.com").and_return([ "93.184.216.34" ])
        allow(provider).to receive(:fetch).with("93.184.216.34").and_return(geo_data.merge(ip: "93.184.216.34"))
      end

      it "resolves a bare hostname to an IP and records both" do
        result = lookup.call("example.com")

        expect(result[:query]).to eq("example.com")
        expect(result[:query_type]).to eq("url")
        expect(result[:ip]).to eq("93.184.216.34")
      end

      it "accepts a full URL and resolves its host" do
        result = lookup.call("https://example.com/some/path")

        expect(result[:query]).to eq("https://example.com/some/path")
        expect(result[:query_type]).to eq("url")
        expect(result[:ip]).to eq("93.184.216.34")
      end
    end

    context "when a hostname resolves to multiple IPs" do
      it "uses the first resolved IP" do
        allow(Resolv).to receive(:getaddresses)
          .with("example.com").and_return([ "93.184.216.34", "93.184.216.35" ])
        allow(provider).to receive(:fetch).with("93.184.216.34").and_return(geo_data)

        result = lookup.call("example.com")

        expect(result[:ip]).to eq("93.184.216.34")
      end
    end

    context "with invalid input" do
      it "raises InvalidInput for something that is neither an IP nor a resolvable host" do
        allow(Resolv).to receive(:getaddresses).with("not a valid input!!").and_return([])

        expect { lookup.call("not a valid input!!") }
          .to raise_error(Geolocation::Lookup::InvalidInput)
      end

      it "raises InvalidInput for blank input" do
        expect { lookup.call("") }.to raise_error(Geolocation::Lookup::InvalidInput)
      end

      it "raises InvalidInput when a hostname cannot be resolved" do
        allow(Resolv).to receive(:getaddresses).with("nonexistent.invalid").and_return([])

        expect { lookup.call("nonexistent.invalid") }
          .to raise_error(Geolocation::Lookup::InvalidInput)
      end
    end

    context "with a private or reserved IP" do
      it "rejects a private IP without calling the provider" do
        expect(provider).not_to receive(:fetch)

        expect { lookup.call("192.168.1.1") }
          .to raise_error(Geolocation::Lookup::UnsupportedIP)
      end

      it "rejects loopback" do
        expect(provider).not_to receive(:fetch)
        expect { lookup.call("127.0.0.1") }
          .to raise_error(Geolocation::Lookup::UnsupportedIP)
      end
    end

    context "when the provider fails" do
      it "lets the ProviderError propagate" do
        allow(provider).to receive(:fetch).and_raise(Geolocation::ProviderError, "boom")

        expect { lookup.call("8.8.8.8") }
          .to raise_error(Geolocation::ProviderError, "boom")
      end
    end
  end

  it "defaults to the configured provider when none is injected" do
    expect(Geolocation.provider_class).to eq(Geolocation::IpstackProvider)
  end
end

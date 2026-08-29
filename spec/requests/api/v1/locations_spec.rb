require "rails_helper"

RSpec.describe "Api::V1::Locations", type: :request do
  let(:token) { ENV.fetch("API_TOKEN", "dev-local-token") }
  let(:auth_headers) { { "Authorization" => "Bearer #{token}" } }

  let(:ipstack_body) do
    {
      "ip" => "8.8.8.8", "type" => "ipv4",
      "continent_name" => "North America",
      "country_name" => "United States", "country_code" => "US",
      "region_name" => "California", "city" => "Mountain View",
      "zip" => "94043", "latitude" => 37.386, "longitude" => -122.0838
    }.to_json
  end

  def stub_ipstack(ip)
    stub_request(:get, %r{\Ahttp://api\.ipstack\.com/#{Regexp.escape(ip)}})
      .to_return(status: 200, body: ipstack_body)
  end

  describe "authentication" do
    it "rejects requests without a token" do
      post "/api/v1/locations", params: { query: "8.8.8.8" }
      expect(response).to have_http_status(:unauthorized)
      expect(json["errors"]).to be_present
    end

    it "rejects requests with a wrong token" do
      post "/api/v1/locations",
           params: { query: "8.8.8.8" },
           headers: { "Authorization" => "Bearer nope" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/locations" do
    it "creates a location from an IP and returns 201 with JSON:API data" do
      stub_ipstack("8.8.8.8")

      post "/api/v1/locations", params: { query: "8.8.8.8" }, headers: auth_headers

      expect(response).to have_http_status(:created)
      expect(json.dig("data", "attributes", "city")).to eq("Mountain View")
      expect(Location.count).to eq(1)
    end

    it "reuses a stored location instead of calling the provider again" do
      create(:location, query: "8.8.8.8")

      post "/api/v1/locations", params: { query: "8.8.8.8" }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(Location.count).to eq(1)
      expect(a_request(:get, /ipstack/)).not_to have_been_made
    end

    it "returns 422 for a private IP" do
      post "/api/v1/locations", params: { query: "192.168.1.1" }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"].first["detail"]).to match(/private or reserved/)
    end

    it "returns 422 for blank input" do
      post "/api/v1/locations", params: { query: "" }, headers: auth_headers
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 502 when the provider fails" do
      stub_request(:get, /ipstack/).to_return(
        status: 200,
        body: { "success" => false, "error" => { "info" => "quota exceeded" } }.to_json
      )

      post "/api/v1/locations", params: { query: "8.8.8.8" }, headers: auth_headers
      expect(response).to have_http_status(:bad_gateway)
    end
  end

  describe "GET /api/v1/locations/:query" do
    it "returns a stored location" do
      create(:location, query: "8.8.8.8", city: "Mountain View")

      get "/api/v1/locations/8.8.8.8", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(json.dig("data", "attributes", "city")).to eq("Mountain View")
    end

    it "returns 404 for an unknown query" do
      get "/api/v1/locations/1.2.3.4", headers: auth_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/locations/:query" do
    it "deletes a stored location and returns 204" do
      create(:location, query: "8.8.8.8")

      delete "/api/v1/locations/8.8.8.8", headers: auth_headers

      expect(response).to have_http_status(:no_content)
      expect(Location.exists?(query: "8.8.8.8")).to be(false)
    end

    it "returns 404 when deleting something that doesn't exist" do
      delete "/api/v1/locations/1.2.3.4", headers: auth_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  # Small helper to parse JSON responses.
  def json
    JSON.parse(response.body)
  end
end

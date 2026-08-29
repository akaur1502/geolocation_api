FactoryBot.define do
    factory :location do
      sequence(:query) { |n| "8.8.8.#{n}" }
      query_type { "ip" }
      ip { query }
      ip_type { "ipv4" }
      continent_name { "North America" }
      country_name { "United States" }
      country_code { "US" }
      region_name { "California" }
      city { "Mountain View" }
      zip { "94043" }
      latitude { 37.386 }
      longitude { -122.0838 }
    end
  end

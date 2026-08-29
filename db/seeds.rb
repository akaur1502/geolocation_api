# Seed data so the API has something to return immediately after startup.
#
# These are static records (no provider call), so seeding always succeeds even
# without an ipstack key configured. Uses find_or_create_by! so re-running seeds
# is idempotent.

sample_locations = [
  {
    query: "8.8.8.8", query_type: "ip", ip: "8.8.8.8", ip_type: "ipv4",
    continent_name: "North America", country_name: "United States",
    country_code: "US", region_name: "California", city: "Mountain View",
    zip: "94043", latitude: 37.386, longitude: -122.0838
  },
  {
    query: "1.1.1.1", query_type: "ip", ip: "1.1.1.1", ip_type: "ipv4",
    continent_name: "Oceania", country_name: "Australia",
    country_code: "AU", region_name: "Queensland", city: "Brisbane",
    zip: "4000", latitude: -27.4679, longitude: 153.0281
  },
  {
    query: "github.com", query_type: "url", ip: "140.82.113.3", ip_type: "ipv4",
    continent_name: "North America", country_name: "United States",
    country_code: "US", region_name: "California", city: "San Francisco",
    zip: "94107", latitude: 37.7823, longitude: -122.3933
  }
]

sample_locations.each do |attrs|
  Location.find_or_create_by!(query: attrs[:query]) do |location|
    location.assign_attributes(attrs)
  end
end

puts "Seeded #{Location.count} locations."

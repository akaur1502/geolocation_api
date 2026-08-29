class LocationSerializer
    include JSONAPI::Serializer

    set_type :location
    set_id :query

    attributes :query, :query_type, :ip, :ip_type,
               :continent_name, :country_name, :country_code,
               :region_name, :city, :zip, :latitude, :longitude,
               :created_at
end

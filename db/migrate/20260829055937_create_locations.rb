class CreateLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :locations do |t|
      # Identity / lookup
      t.string  :query,      null: false             # original input (IP or URL)
      t.string  :query_type, null: false             # "ip" or "url"
      t.string  :ip,         null: false             # resolved IP that was geolocated

      # Geolocation data (normalized provider output)
      t.string  :ip_type                              # "ipv4" / "ipv6"
      t.string  :continent_name
      t.string  :country_name
      t.string  :country_code
      t.string  :region_name
      t.string  :city
      t.string  :zip
      t.decimal :latitude,  precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6

      t.timestamps
    end

    # Look up and delete by query; also enforce no duplicate queries.
    add_index :locations, :query, unique: true
    add_index :locations, :ip
  end
end

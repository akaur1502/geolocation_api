# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_29_055937) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "locations", force: :cascade do |t|
    t.string "city"
    t.string "continent_name"
    t.string "country_code"
    t.string "country_name"
    t.datetime "created_at", null: false
    t.string "ip", null: false
    t.string "ip_type"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "query", null: false
    t.string "query_type", null: false
    t.string "region_name"
    t.datetime "updated_at", null: false
    t.string "zip"
    t.index ["ip"], name: "index_locations_on_ip"
    t.index ["query"], name: "index_locations_on_query", unique: true
  end
end

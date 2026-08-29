require "rails_helper"

RSpec.describe Location, type: :model do
  it "is valid with the factory defaults" do
    expect(build(:location)).to be_valid
  end

  describe "validations" do
    it "requires a query" do
      location = build(:location, query: nil)
      expect(location).not_to be_valid
      expect(location.errors[:query]).to be_present
    end

    it "requires a unique query" do
      create(:location, query: "8.8.8.8")
      duplicate = build(:location, query: "8.8.8.8")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:query]).to be_present
    end

    it "requires a query_type" do
      expect(build(:location, query_type: nil)).not_to be_valid
    end

    it "only allows 'ip' or 'url' as query_type" do
      expect(build(:location, query_type: "ip")).to be_valid
      expect(build(:location, query_type: "url")).to be_valid
      expect(build(:location, query_type: "domain")).not_to be_valid
    end

    it "requires an ip" do
      expect(build(:location, ip: nil)).not_to be_valid
    end
  end
end

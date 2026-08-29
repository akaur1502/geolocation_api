class Location < ApplicationRecord
    QUERY_TYPES = %w[ip url].freeze

    validates :query, presence: true, uniqueness: true
    validates :query_type, presence: true, inclusion: { in: QUERY_TYPES }
    validates :ip, presence: true
end

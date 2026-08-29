module Geolocation
    mattr_accessor :provider_class
    self.provider_class = Geolocation::IpstackProvider
end

module Geolocation
  # Stored as a string so this doesn't force the class to load during boot,
  # before autoloading is ready.
  PROVIDER_NAME = "Geolocation::IpstackProvider".freeze

  def self.provider_class
    PROVIDER_NAME.constantize
  end
end

module Geolocation
    # Contract that every geolocation provider must implement.
    class Provider
      def fetch(ip)
        raise NotImplementedError, "#{self.class} must implement #fetch"
      end
    end
end

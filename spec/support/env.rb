RSpec.configure do |config|
    config.before(:suite) do
      ENV["IPSTACK_API_KEY"] ||= "test-key"
    end
end

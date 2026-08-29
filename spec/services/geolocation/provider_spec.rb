require "rails_helper"

RSpec.describe Geolocation::Provider do
  it "requires subclasses to implement #fetch" do
    expect { described_class.new.fetch("8.8.8.8") }
      .to raise_error(NotImplementedError, /must implement #fetch/)
  end
end

require "test_launcher/frameworks/base"
require "test_launcher/frameworks/minitest"
require "test_launcher/frameworks/rspec"


module TestLauncher
  module Frameworks
    def self.current_framework
      RSpec
    end
  end
end

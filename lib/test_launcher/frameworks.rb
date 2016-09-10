require "test_launcher/frameworks/base"
require "test_launcher/frameworks/minitest"


module TestLauncher
  module Frameworks
    def self.current_framework
      Minitest
    end
  end
end

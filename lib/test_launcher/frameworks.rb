require "test_launcher/frameworks/base"
require "test_launcher/frameworks/minitest"
require "test_launcher/frameworks/rspec"


module TestLauncher
  module Frameworks
    def self.guess_framework(framework_name)
      if framework_name == "rspec"
        RSpec
      elsif framework_name == "minitest"
        Minitest
      else
        # TODO:

        # guessing is broken
        # many projects will have files of both types.  Try both in that case?

        [Minitest, RSpec].find(&:active?)
      end
    end
  end
end
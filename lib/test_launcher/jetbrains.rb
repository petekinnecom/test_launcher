require "test_launcher/frameworks/minitest"

module TestLauncher
  module Jetbrains

    def self.launch
      test_case = Frameworks::Minitest::TestCase.new(file: ARGV.first, example: ARGV.last.split("=").last)
      Dir.chdir('/')
      exec TestLauncher::Frameworks::Minitest::Runner.new.single_example(test_case)
    end
  end
end

TestLauncher::Jetbrains.launch

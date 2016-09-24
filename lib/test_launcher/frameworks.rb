require "test_launcher/frameworks/base"
require "test_launcher/frameworks/minitest"
require "test_launcher/frameworks/rspec"

module TestLauncher
  module Frameworks
    def self.locate(framework_name:, input:, run_all:, shell:, searcher:)
      framework = guess_framework(framework_name)
      search_results = framework::Locator.new(input, searcher).prioritized_results
      runner = framework::Runner.new

      Implementation::Consolidator.consolidate(search_results, shell, runner, run_all)
    end

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

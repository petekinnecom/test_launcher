require "test_launcher/frameworks/base"
require "test_launcher/frameworks/minitest"
require "test_launcher/frameworks/rspec"

module TestLauncher
  module Frameworks
    def self.locate(framework_name:, input:, run_all:, shell:, searcher:)
      frameworks = guess_frameworks(framework_name)

      frameworks.each do |framework|
        search_results = framework::Locator.new(input, searcher).prioritized_results
        runner = framework::Runner.new

        command = Implementation::Consolidator.consolidate(search_results, shell, runner, run_all)

        return command if command
      end
    end

    def self.guess_frameworks(framework_name)
      if framework_name == "rspec"
        [RSpec]
      elsif framework_name == "minitest"
        [Minitest]
      else
        [Minitest, RSpec].select(&:active?)
      end
    end
  end
end

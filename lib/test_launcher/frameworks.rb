require "test_launcher/frameworks/implementation/consolidator"


module TestLauncher
  module Frameworks
    def self.locate(request:, shell:, searcher:)
      request.frameworks.each do |framework|
        search_results = framework::Locator.new(request, searcher).prioritized_results
        runner = framework::Runner.new

        command = Implementation::Consolidator.consolidate(search_results, shell, runner)

        return command if command
      end

      nil
    end

  end
end

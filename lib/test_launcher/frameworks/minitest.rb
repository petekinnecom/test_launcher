require "test_launcher/frameworks/minitest/finder"
require "test_launcher/frameworks/minitest/consolidator"

module TestLauncher
  module Frameworks
    module Minitest
      def self.command_for(input, shell:, searcher:, run_all:)
        search_results = Finder.find(input, searcher)

        Consolidator.consolidate(search_results, shell, run_all)
      end
    end
  end
end

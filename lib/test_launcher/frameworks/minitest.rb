module TestLauncher
  module Frameworks
    module Minitest

      class Searcher < SimpleDelegator
      end

      def self.command_for(input, shell:, searcher:, run_all:)
        minitest_searcher = Searcher.new(searcher)
        search_results = ExampleFinder.find(input, minitest_searcher)
        Consolidator.consolidate(search_results, shell, run_all)
      end
    end
  end
end

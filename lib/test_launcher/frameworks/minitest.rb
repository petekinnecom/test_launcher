module TestLauncher
  module Frameworks
    module Minitest
      class Runner < Struct.new(:shell)
        def single_example(result)
          Wrappers::SingleTest.new(result).to_s
        end

        def single_file(result)
          Wrappers::SingleFile.new(result).to_s
        end

        def multiple_files(results)
          Wrappers::MultipleFiles.wrap(results).to_s
        end
      end

      require "test_launcher/search_results_base"
      class SearchResults < SearchResultsBase
        private

        def file_name_regex
          /.*_test\.rb/
        end

        def file_name_pattern
          '*_test.rb'
        end

        def regex_pattern
          "^\s*def .*#{query}.*"
        end
      end
    end
  end
end

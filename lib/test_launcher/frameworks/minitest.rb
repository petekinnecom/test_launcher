require "test_launcher/search_results_base"
require "test_launcher/runner_base"

module TestLauncher
  module Frameworks
    module Minitest
      class Runner < RunnerBase
        def single_example(result)
          method_name = result.line[/\s*def\s+(.*)\s*/, 1]
          %{cd #{result.app_root} && ruby -I test #{result.relative_test_path} --name=/#{method_name}/}
        end

        def one_or_more_files(results)
          %{cd #{results.first.app_root} && ruby -I test -e 'ARGV.each { |file| require(Dir.pwd + "/" + file) }' #{results.map(&:relative_test_path).join(" ")}}
        end
      end

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

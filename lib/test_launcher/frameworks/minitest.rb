require "test_launcher/frameworks/base"

module TestLauncher
  module Frameworks
    module Minitest

      def self.active?
        ! Dir.glob("**/test/**/*_test.rb").empty?
      end

      class Runner < Base::Runner
        def single_example(result)
          %{cd #{result.app_root} && ruby -I test #{result.relative_test_path} --name=/#{result.example}/}
        end

        def one_or_more_files(results)
          %{cd #{results.first.app_root} && ruby -I test -e 'ARGV.each { |file| require(Dir.pwd + "/" + file) }' #{results.map(&:relative_test_path).join(" ")}}
        end
      end

      class SearchResults < Base::SearchResults
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

        def test_case_class
          TestCase
        end
      end

      class TestCase < Base::TestCase
        def self.from_search(file:, line:)
          if line
            new(
              file: file,
              example: line[/\s*def\s+(.*)\s*/, 1]
            )
          else
            new(file: file)
          end
        end

        def test_root_folder_name
          "test"
        end
      end
    end
  end
end

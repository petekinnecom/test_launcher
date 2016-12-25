require "test_launcher/frameworks/base"
require "test_launcher/base_error"

module TestLauncher
  module Frameworks
    module Elixir
      def self.active?
        # Do not do this outside of the shell.
        ! Dir.glob("**/test/**/*.exs").empty?
      end

      def self.test_case(*a)
        TestCase.new(*a)
      end

      def self.searcher(*a)
        Searcher.new(*a)
      end

      def self.runner(*a)
        Runner.new(*a)
      end

      class Searcher < Base::Searcher
        MultipleByLineMatches = Class.new(BaseError)

        def by_line(file_pattern, line_number)
          files = test_files(file_pattern)
          return unless files.any?
          raise multiple_files_error if files.size > 1

          {
            file: files.first,
            line_number: line_number
          }
        end

        private

        def file_name_regex
          /.*_test\.exs$/
        end

        def file_name_pattern
          "*_test.exs"
        end

        def example_name_regex(query="")
          "^\s*test\s+\".*#{query}.*\"\s+do"
        end

        def multiple_files_error
          MultipleByLineMatches.new(<<-MSG)
It looks like you are running a line number in a test file.

Multiple files have been found that match your query.

This case is not supported.
          MSG
        end
      end

      class Runner < Base::Runner
        def single_example(test_case)
          %{cd #{test_case.app_root} && mix test #{test_case.file}:#{test_case.line_number}}
        end

        def multiple_examples_same_file(test_cases)
          one_or_more_files(test_cases.first)
        end

        def one_or_more_files(test_cases)
          %{cd #{test_cases.first.app_root} && mix test #{test_cases.map(&:file).join(" ")}}
        end
      end

      class TestCase < Base::TestCase
        def test_root_dir_name
          "test"
        end
      end
    end
  end
end

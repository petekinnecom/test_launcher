require "shellwords"
require "test_launcher/frameworks/base"

module TestLauncher
  module Frameworks
    module Mochajs

      def self.active?(searcher)
        # just disable this cause it doesn't really work and it might
        # help speed things up.
        false
      end

      def self.test_case(*a, **o)
        TestCase.new(*a, **o)
      end

      def self.searcher(*a, **o)
        Searcher.new(*a, **o)
      end

      def self.runner(*a, **o)
        Runner.new(*a, **o)
      end

      class Searcher < Base::Searcher

        def by_line(file_pattern, line_number)
          files = test_files(file_pattern)
          return [] unless files.any?
          raise multiple_files_error if files.size > 1
          #
          file = files.first
          grep_results = raw_searcher.grep(example_name_regex, file_pattern: file)

          if grep_results.empty?
            # the file exists, but doesn't appear to contain any tests...
            # we'll try to run it anyway
            return [file: file]
          end

          best_result =
            grep_results
              .select {|r| line_number >= r[:line_number]}
              .min_by {|r| line_number - r[:line_number]}

          if best_result
            [{
              file: best_result[:file],
              example_name: best_result[:line].match(/(it|describe)\(["'](.*)['"],/)[2],
              line_number: best_result[:line_number]
            }]
          else
            # line number outside of example. Run whole file
            [{
              file: grep_results.first[:file]
            }]
          end
        end

        private

        def file_name_regex
          /.*pec\.js/
        end

        def file_name_pattern
          '*pec.js'
        end

        def example_name_regex(query="")
          "^\s*(it|describe).*(#{query}).*,.*"
        end
      end

      class Runner < Base::Runner
        def by_line_number(test_case)
          if test_case.example
            single_example(test_case, exact_match: true)
          else
            single_file(test_case)
          end
        end

        def single_example(test_case, **_)
          multiple_examples_same_root([test_case])
        end

        def multiple_examples_same_file(test_cases)
          test_case = test_cases.first
          single_example(test_case)
        end

        def multiple_examples_same_root(test_cases)
          %{cd #{test_cases.first.app_root} && npm run test #{test_cases.map(&:file).join(" ")} -- --grep #{Shellwords.escape(test_cases.first.example)}}
        end

        def one_or_more_files(test_cases)
          %{cd #{test_cases.first.app_root} && npm run test #{test_cases.map(&:file).join(" ")}}
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

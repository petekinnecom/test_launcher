require 'shellwords'
require "test_launcher/base_error"

module TestLauncher
  module Frameworks
    NotSupportedError = Class.new(BaseError)

    module Generic
      def self.active?
        true
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
        MultipleByLineMatches = Class.new(BaseError)

        def by_line(*)
          return []
        end

        def examples(*)
          []
        end

        def grep(*)
          []
        end

        private

        def file_name_regex
          /\.rb$/
        end

        def file_name_pattern
          "*.rb"
        end
      end

      class Runner < Base::Runner
        def by_line_number(test_case)
          raise NotSupportedError.new("You should not have hit this error. File an issue. :(")
        end

        def single_example(test_case, name: test_case.example, exact_match: false)
          raise NotSupportedError.new("You should not have hit this error. File an issue. :(")
        end

        def multiple_examples_same_file(test_cases)
          raise NotSupportedError.new("You should not have hit this error. File an issue. :(")
        end

        def multiple_examples_same_root(test_cases)
          raise NotSupportedError.new("You should not have hit this error. File an issue. :(")
        end

        def one_or_more_files(test_cases)
          %{#{test_cases.first.file_runner} #{test_cases.map(&:file).uniq.join(" ")}}
        end
      end

      class TestCase < Base::TestCase
        def file_runner
          "ruby"
        end
      end
    end
  end
end

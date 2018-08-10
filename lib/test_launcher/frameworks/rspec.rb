require "shellwords"
require "test_launcher/frameworks/base"

module TestLauncher
  module Frameworks
    module RSpec

      def self.active?
        `git ls-files '*_spec.rb'`.split("\n").any?
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

        def by_line(file_pattern, line_number)
          files = test_files(file_pattern)

          files.map {|file|
            {
              file: file,
              line_number: line_number
            }
          }
        end

        private

        def file_name_regex
          /.*_spec\.rb/
        end

        def file_name_pattern
          '*_spec.rb'
        end

        def example_name_regex(query)
          "^\s*(it|context|(RSpec.)?describe) .*(#{query}).* do.*"
        end
      end

      class Runner < Base::Runner
        def by_line_number(test_case)
          %{cd #{test_case.app_root} && bundle exec rspec #{test_case.file}:#{test_case.line_number}}
        end

        def single_example(test_case, **_)
          multiple_examples_same_root([test_case])
        end

        def multiple_examples_same_file(test_cases)
          test_case = test_cases.first
          single_example(test_case)
        end

        def multiple_examples_same_root(test_cases)
          %{cd #{test_cases.first.app_root} && bundle exec rspec #{test_cases.map(&:file).join(" ")} --example #{Shellwords.escape(test_cases.first.example)}}
        end

        def one_or_more_files(test_cases)
          %{cd #{test_cases.first.app_root} && bundle exec rspec #{test_cases.map(&:file).join(" ")}}
        end
      end

      class TestCase < Base::TestCase
        def test_root_dir_name
          "spec"
        end
      end
    end
  end
end

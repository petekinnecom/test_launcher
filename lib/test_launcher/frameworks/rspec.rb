require "shellwords"
require "test_launcher/frameworks/base"

module TestLauncher
  module Frameworks
    module RSpec

      def self.active?(searcher)
        searcher.ls_files("*_spec.rb").any?
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
          %{cd #{test_case.app_root} && #{test_case.runner} #{test_case.file}:#{test_case.line_number}}
        end

        def single_example(test_case, **_)
          multiple_examples_same_root([test_case])
        end

        def multiple_examples_same_file(test_cases)
          test_case = test_cases.first
          single_example(test_case)
        end

        def multiple_examples_same_root(test_cases)
          %{cd #{test_cases.first.app_root} && #{test_cases.first.runner} #{test_cases.map(&:file).join(" ")} --example #{Shellwords.escape(test_cases.first.example)}}
        end

        def one_or_more_files(test_cases)
          %{cd #{test_cases.first.app_root} && #{test_cases.first.runner} #{test_cases.map(&:file).join(" ")}}
        end
      end

      class TestCase < Base::TestCase
        def test_root_dir_name
          "spec"
        end

        def runner
          @runner ||= begin
            if File.exist?(File.join(app_root, "bin/rspec"))
              "bin/rspec"
            else
              "bundle exec rspec"
            end
          end
        end
      end
    end
  end
end

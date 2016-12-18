require "shellwords"
require "test_launcher/frameworks/base"

module TestLauncher
  module Frameworks
    module RSpec

      def self.active?
        ! Dir.glob("**/*_spec.rb").empty?
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
          return unless files.any?
          raise multiple_files_error if files.size > 1

          {
            file: files.first,
            line_number: line_number
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
          "^\s*(it|context|(RSpec.)?describe) .*#{query}.* do.*"
        end
      end

      class Runner < Base::Runner
        def single_example(test_case, **_)
          %{cd #{test_case.app_root} && rspec #{test_case.file} --example #{Shellwords.escape(test_case.example)}}
        end

        def one_or_more_files(test_cases)
          %{cd #{test_cases.first.app_root} && rspec #{test_cases.map(&:file).join(" ")}}
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

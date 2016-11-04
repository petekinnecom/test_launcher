require "shellwords"

require "test_launcher/frameworks/base"

module TestLauncher
  module Frameworks
    module RSpec

      #TODO: consolidate with Minitest
      def self.commandify(request:, shell:, searcher:)
        return unless active?
        search_results = Locator.new(request, searcher).prioritized_results
        runner = Runner.new

        Implementation::Consolidator.consolidate(search_results, shell, runner)
      end

      def self.active?
        ! Dir.glob("**/*_spec.rb").empty?
      end

      class Runner < Base::Runner
        def single_example(test_case)
          %{cd #{test_case.app_root} && rspec #{test_case.file} --example #{Shellwords.escape(test_case.example)}}
        end

        def one_or_more_files(test_cases)
          %{cd #{test_cases.first.app_root} && rspec #{test_cases.map(&:file).join(" ")}}
        end
      end

      class Locator < Base::Locator
        private

        def file_name_regex
          /.*_spec\.rb/
        end

        def file_name_pattern
          '*_spec.rb'
        end

        def regex_pattern
          "^\s*(it|context|(RSpec.)?describe) .*#{request.query}.* do.*"
        end

        def test_case_class
          TestCase
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

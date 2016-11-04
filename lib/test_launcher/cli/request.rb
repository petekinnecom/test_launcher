require "test_launcher/frameworks/minitest"
require "test_launcher/frameworks/rspec"

module TestLauncher
  module CLI
    class Request
      def initialize(query:, framework: "guess", run_all: false, disable_spring: false, example_name: nil)
        @query = query
        @framework = framework
        @run_all = run_all
        @disable_spring = disable_spring
        @example_name = example_name
      end

      def query
        @query
      end

      def run_all?
        @run_all
      end

      def disable_spring?
        @disable_spring
      end

      def example_name
        @example_name
      end

      def frameworks
        if @framework == "rspec"
          [Frameworks::RSpec]
        elsif @framework == "minitest"
          [Frameworks::Minitest]
        else
          [Frameworks::Minitest, Frameworks::RSpec]
        end
      end
    end
  end
end

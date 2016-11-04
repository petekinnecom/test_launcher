require "test_launcher/frameworks/minitest"
require "test_launcher/frameworks/rspec"

module TestLauncher
  module CLI
    class Request
      def initialize(query:, framework: "guess", run_all: false, disable_spring: false)
        @query = query
        @framework = framework
        @run_all = run_all
        @disable_spring = disable_spring
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

      def frameworks
        if @framework == "rspec"
          [Frameworks::RSpec]
        elsif @framework == "minitest"
          [Frameworks::Minitest]
        else
          [Frameworks::Minitest, Frameworks::RSpec].select(&:active?)
        end
      end
    end
  end
end

module TestLauncher
  module CLI
    class Request
      def initialize(
        search_string:,
        framework:,
        run_all: false,
        disable_spring: false,
        example_name: nil
      )
        @search_string = search_string
        @framework = framework
        @run_all = run_all
        @disable_spring = disable_spring
        @example_name = example_name
      end

      def search_string
        @search_string
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

      def framework
        @framework
      end
    end
  end
end

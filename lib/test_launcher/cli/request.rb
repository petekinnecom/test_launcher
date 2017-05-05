module TestLauncher
  module CLI
    class Request
      def initialize(
        search_string:,
        framework:,
        rerun: false,
        run_all: false,
        disable_spring: false,
        example_name: nil,
        shell:,
        searcher:
      )
        @search_string = search_string
        @framework = framework
        @rerun = rerun
        @run_all = run_all
        @disable_spring = disable_spring
        @example_name = example_name
        @shell = shell
        @searcher = searcher
      end

      def search_string
        @search_string
      end

      def run_all?
        @run_all
      end

      def rerun?
        @rerun
      end

      def disable_spring?
        @disable_spring
      end

      def example_name
        @example_name
      end

      def searcher
        framework.searcher(@searcher)
      end

      def runner(*a)
        framework.runner(*a)
      end

      def test_case(*a)
        framework.test_case(*a)
      end

      def shell
        @shell
      end

      private

      def framework
        @framework
      end
    end
  end
end

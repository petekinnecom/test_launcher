require "test_launcher/frameworks/minitest"
require "test_launcher/frameworks/rspec"



module TestLauncher
  module CLI
    class SearchOptions
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
    end

    class Request
      def initialize(
        shell:,
        searcher:,
        query:,
        framework: "guess",
        run_all: false,
        disable_spring: false,
        example_name: nil
      )

        @shell = shell
        @searcher = searcher
        @framework = framework

        # run_options
        @query = query
        @run_all = run_all
        @disable_spring = disable_spring
        @example_name = example_name
      end

      def run_options
        SearchOptions.new(
          query: @query,
          framework: @framework,
          run_all: @run_all,
          disable_spring: @disable_spring,
          example_name: @example_name
        )
      end

      def launch
        command = nil
        framework_requests.each { |request|
          command = request.command
          break if command
        }

        if command
          shell.exec command
        else
          shell.warn "No tests found."
        end
      rescue BaseError => e
        shell.warn(e)
      end

      def framework_requests
        if @framework == "rspec"
          # [CLI::RSpec::Request]
        elsif @framework == "minitest"
          [
            Frameworks::Minitest::SearchRequest.new(
              shell: shell,
              searcher: searcher,
              run_options: run_options
            )
          ]
        else
          # [Frameworks::Minitest, Frameworks::RSpec]
        end
      end

      def shell
        @shell
      end

      def searcher
        @searcher
      end

    end
  end
end

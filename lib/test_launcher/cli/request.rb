require "test_launcher/frameworks/minitest"
require "test_launcher/frameworks/rspec"



module TestLauncher
  module CLI
    class Options
      def initialize(
        query:,
        frameworks:,
        run_all: false,
        disable_spring: false,
        example_name: nil,
        shell:,
        searcher:
      )
        @query = query
        @frameworks = frameworks
        @run_all = run_all
        @disable_spring = disable_spring
        @example_name = example_name
        @shell = shell
        @searcher = searcher
      end

      def request
        runs = @frameworks.map {|framework|
          RunOptions.new(
            framework: framework,
            query: @query,
            run_all: @run_all,
            disable_spring: @disable_spring,
            example_name: @example_name,
          )
        }

        Request.new(
          shell: @shell,
          searcher: @searcher,
          runs: runs
        )
      end
    end

    class RunOptions
      def initialize(
        query:,
        framework:,
        run_all: false,
        disable_spring: false,
        example_name: nil
      )
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

      def framework
        @framework
      end
    end

    class Request
      attr_reader :shell, :searcher, :runs
      def initialize(shell:, searcher:, runs:)
        @shell = shell
        @searcher = searcher
        @runs = runs
      end

      def launch
        if command
          shell.exec command
        else
          shell.warn "No tests found."
        end
      rescue BaseError => e
        shell.warn(e)
      end

      def command
        return @command if defined?(@command)
        @command = nil
        requests.each { |request|
          @command = request.command
          break if @command
        }
        @command
      end

      def requests
        runs.map {|run_options| build_request(run_options)}
      end

      def build_request(run_options)
        Frameworks::Base::GenericRequest.new(
          shell: shell,
          searcher: searcher,
          run_options: run_options,
        )
      end
    end
  end
end

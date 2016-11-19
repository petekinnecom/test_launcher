require "test_launcher/frameworks/minitest"
require "test_launcher/frameworks/rspec"



module TestLauncher
  module CLI
    class RawOptions
      def initialize(
        query:,
        frameworks:,
        run_all: false,
        disable_spring: false,
        example_name: nil
      )
        @query = query
        @frameworks = frameworks
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
        @frameworks
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
      attr_reader :shell, :searcher, :raw_options
      def initialize(shell:, searcher:, raw_options:)
        @shell = shell
        @searcher = searcher
        @raw_options = raw_options
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
        framework_requests.each { |request|
          @command = request.command
          break if @command
        }
        @command
      end

      def framework_requests
        raw_options.frameworks.map {|f| build_request(f)}
      end

      def build_request(framework)
        run_options = RunOptions.new(
          query: raw_options.query,
          framework: framework,
          run_all: raw_options.run_all?,
          disable_spring: raw_options.disable_spring?,
          example_name: raw_options.example_name,
        )

        Frameworks::Base::GenericRequest.new(
          shell: shell,
          searcher: searcher,
          run_options: run_options,
        )
      end
    end
  end
end

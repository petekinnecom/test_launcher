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
      attr_reader :shell, :searcher, :framework_name, :run_options
      def initialize(shell:, searcher:, run_options:, framework_name: "guess")
        @shell = shell
        @searcher = searcher
        @framework_name = framework_name
        @run_options = run_options
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
        if @framework_name == "rspec"
          # [CLI::RSpec::Request]
        elsif @framework_name == "minitest"
          [
            Frameworks::Minitest::GenericRequest.new(
              shell: shell,
              searcher: searcher,
              run_options: run_options
            )
          ]
        else
          # [Frameworks::Minitest, Frameworks::RSpec]
        end
      end
    end
  end
end

require "test_launcher/frameworks/minitest"
require "test_launcher/frameworks/rspec"



module TestLauncher
  module CLI
    class Options
      def initialize(
        search_string:,
        frameworks:,
        run_all: false,
        disable_spring: false,
        example_name: nil,
        shell:,
        searcher:
      )
        @search_string = search_string
        @frameworks = frameworks
        @run_all = run_all
        @disable_spring = disable_spring
        @example_name = example_name
        @shell = shell
        @searcher = searcher
      end

      def request
        requests = @frameworks.map {|framework|
          Request.new(
            framework: framework,
            search_string: @search_string,
            run_all: @run_all,
            disable_spring: @disable_spring,
            example_name: @example_name,
          )
        }

        Query.new(
          shell: @shell,
          searcher: @searcher,
          requests: requests
        )
      end
    end

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

    class Query
      attr_reader :shell, :searcher, :requests
      def initialize(shell:, searcher:, requests:)
        @shell = shell
        @searcher = searcher
        @requests = requests
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
        queries.each { |query|
          @command = query.command
          break if @command
        }
        @command
      end

      def queries
        requests.map {|request| build_query(request)}
      end

      def build_query(request)
        Frameworks::Base::GenericQuery.new(
          shell: shell,
          searcher: searcher,
          request: request,
        )
      end
    end
  end
end

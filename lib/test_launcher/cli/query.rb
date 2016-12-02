require "test_launcher/base_error"
require "test_launcher/queries"
require "test_launcher/cli/request"

module TestLauncher
  module CLI
    class Query
      attr_reader :shell, :searcher
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

      private

      def queries
        requests.map {|request| Queries::GenericQuery.new(request: request)}
      end

      def requests
        @frameworks.map {|framework|
          Request.new(
            framework: framework,
            search_string: @search_string,
            run_all: @run_all,
            disable_spring: @disable_spring,
            example_name: @example_name,
            shell: shell,
            searcher: searcher
          )
        }
      end
    end
  end
end

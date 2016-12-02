require "test_launcher/base_error"
require "test_launcher/queries"
require "test_launcher/cli/request"

module TestLauncher
  module CLI
    class Query < BaseQuery
      attr_reader :shell, :searcher

      def command
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

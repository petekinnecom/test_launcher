require "test_launcher/shell/runner"
require "test_launcher/search"
require "test_launcher/cli/input_parser"
require "test_launcher/queries"

module TestLauncher
  module CLI

    class MultiRequestQuery < Struct.new(:requests)

      def command
        command = nil
        command_finders.each do |command_finder|
          command = command_finder.generic_search
          break if command
        end
        command
      end

      def command_finders
        requests.map {|request| Queries::CommandFinder.new(request)}
      end
    end

    def self.launch(argv, env, shell: Shell::Runner.new(log_path: "/tmp/test_launcher.log"), searcher: Search.searcher(shell))
      requests = CLI::InputParser.new(
        argv,
        env
      ).requests(shell: shell, searcher: searcher)

      command = MultiRequestQuery.new(requests).command

      if command
        shell.exec command
      else
        shell.warn "No tests found."
      end
    rescue BaseError => e
      shell.warn(e)
    end
  end
end

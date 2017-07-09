require "test_launcher/shell/history_runner"
require "test_launcher/search"
require "test_launcher/cli/input_parser"
require "test_launcher/queries"
require "test_launcher/cli/request"

module TestLauncher
  module CLI
    class MultiFrameworkQuery < Struct.new(:cli_options)
      def command
        command = nil
        command_finders.each do |command_finder|
          command = command_finder.generic_search
          break if command
        end

        return unless command

        if cli_options.root_override
          command = command.gsub(Dir.pwd, cli_options.root_override)
        end

        if cli_options.wrap
          cli_options.wrap.sub("%cmd", command)
        else
          command
        end
      end

      def command_finders
        cli_options.frameworks.map do |framework|
          Queries::CommandFinder.new(request_for(framework))
        end
      end

      def request_for(framework)
        Request.new(
          framework: framework,
          search_string: cli_options.search_string,
          rerun: cli_options.rerun,
          run_all: cli_options.run_all,
          disable_spring: cli_options.disable_spring,
          example_name: cli_options.example_name,
          shell: cli_options.shell,
          searcher: cli_options.searcher,
          root_override: cli_options.root_override
        )
      end
    end

    def self.launch(argv, env, shell: Shell::HistoryRunner.new, searcher: Search.searcher(shell))
      options = CLI::InputParser.new(
        argv,
        env
      ).parsed_options(shell: shell, searcher: searcher)

      if options.rerun
        shell.reexec
      elsif command = MultiFrameworkQuery.new(options).command
        shell.exec command
      else
        shell.warn "No tests found."
      end
    rescue BaseError => e
      shell.warn(e)
    end
  end
end

require "test_launcher/search/git"
require "test_launcher/shell/runner"

require "test_launcher/cli/launcher"
require "test_launcher/cli/request"

module TestLauncher
  module IntegrationHelper
    private

    def system_path(relative_dir)
      File.join(Dir.pwd, relative_dir)
    end

    def launch(query, run_all: false, framework:)
      request = CLI::Request.new(
        query: query,
        run_all: run_all,
        framework: framework
      )

      shell = Shell::Runner.new

      CLI::Launcher.launch(
        request: request,
        shell: shell,
        searcher: Search::Git.new(shell)
      )
    end
  end
end

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

    def launch(query, run_all: false, framework:, name: nil)
      shell = Shell::Runner.new
      request = CLI::Request.new(
        shell: shell,
        searcher: Search::Git.new(shell),

        query: query,
        run_all: run_all,
        framework: framework,
        example_name: name
      )


      request.launch
    end
  end
end

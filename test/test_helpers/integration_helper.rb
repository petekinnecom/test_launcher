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

    def launch(search_string, run_all: false, framework:, name: nil)
      f = framework == "minitest" ? Frameworks::Minitest : Frameworks::RSpec

      shell = Shell::Runner.new
      options = CLI::Options.new(
        search_string: search_string,
        run_all: run_all,
        frameworks: [f],
        example_name: name,
        shell: shell,
        searcher: Search::Git.new(shell),
      )

      options.request.launch
    end
  end
end

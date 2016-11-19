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
      f = framework == "minitest" ? Frameworks::Minitest : Frameworks::RSpec

      options = CLI::RawOptions.new(
        query: query,
        run_all: run_all,
        frameworks: [f],
        example_name: name
      )

      shell = Shell::Runner.new
      request = CLI::Request.new(
        shell: shell,
        searcher: Search::Git.new(shell),
        raw_options: options,
      )

      request.launch
    end
  end
end

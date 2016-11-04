require "test_launcher/shell/runner"
require "test_launcher/search/git"
require "test_launcher/cli/input_parser"
require "test_launcher/cli/launcher"

module TestLauncher
  module CLI
    def self.launch(argv, env)
      shell = Shell::Runner.new(log_path: "/tmp/test_launcher.log")
      searcher = Search::Git.new(shell)
      request = TestLauncher::CLI::InputParser.new(argv, env).request

      TestLauncher::CLI::Launcher.launch(
        shell: shell,
        searcher: searcher,
        request: request
      )
    end
  end
end

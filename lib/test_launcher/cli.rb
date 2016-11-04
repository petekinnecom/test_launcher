require "test_launcher/cli/input_parser"
require "test_launcher/cli/launcher"
require "test_launcher"

module TestLauncher
  module CLI
    def self.launch(argv, env)
      request = TestLauncher::CLI::InputParser.new(argv, env).request

      shell = Shell::Runner.new(log_path: "/tmp/test_launcher.log")
      searcher = Search::Git.new(shell)

      TestLauncher::CLI::Launcher.launch(
        shell: shell,
        searcher: searcher,
        request: request
      )
    end
  end
end

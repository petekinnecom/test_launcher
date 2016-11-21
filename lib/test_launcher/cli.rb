require "test_launcher/shell/runner"
require "test_launcher/search/git"
require "test_launcher/cli/input_parser"

module TestLauncher
  module CLI
    def self.launch(argv, env)
      shell = Shell::Runner.new(log_path: "/tmp/test_launcher.log")
      searcher = Search::Git.new(shell)
      input_parser = TestLauncher::CLI::InputParser.new(argv, env)

      query = input_parser.query(shell: shell, searcher: searcher)

      query.launch
    end
  end
end

require "test_launcher/version"

require "test_launcher/shell/runner"
require "test_launcher/searchers/git_searcher"
require "test_launcher/frameworks"


module TestLauncher
  def self.launch(input, run_all: false)
    shell = Shell::Runner.new(
      log_path: '/tmp/test_launcher.log',
      working_directory: '.',

    )

    searcher = Searchers::GitSearcher.new(shell)
    command = Frameworks.command_for(input, shell: shell, searcher: searcher, run_all: run_all)

    shell.exec command
  end
end

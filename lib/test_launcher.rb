require "test_launcher/version"

require "test_launcher/shell/runner"
require "test_launcher/searchers/git_searcher"
require "test_launcher/example_finder"
require "test_launcher/consolidator"
require "test_launcher/frameworks"


module TestLauncher
  def self.launch(input, run_all: false)
    shell = Shell::Runner.new(
      log_path: '/tmp/test_launcher.log',
      working_directory: '.',
    )

    searcher = Searchers::GitSearcher.new(shell)
    framework = Frameworks.current_framework

    search_results = framework::SearchResults.new(input, searcher).prioritized_results
    runner = framework::Runner.new(shell)

    command = Consolidator.consolidate(search_results, shell, runner, run_all)
    shell.exec command
  end
end

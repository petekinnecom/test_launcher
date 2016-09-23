require "test_launcher/version"

require "test_launcher/shell/runner"
require "test_launcher/search/git_searcher"
require "test_launcher/consolidator"
require "test_launcher/frameworks"


module TestLauncher
  def self.launch(input, framework: "guess", run_all: false)
    shell = Shell::Runner.new(log_path: '/tmp/test_launcher.log')

    searcher = Searchers::GitSearcher.new(shell)
    framework = Frameworks.guess_framework(framework)

    search_results = framework::SearchResults.new(input, searcher).prioritized_results
    runner = framework::Runner.new

    command = Consolidator.consolidate(search_results, shell, runner, run_all)
    shell.exec command
  end
end

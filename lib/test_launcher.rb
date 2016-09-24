require "test_launcher/version"

require "test_launcher/shell/runner"
require "test_launcher/search/git"
require "test_launcher/frameworks"

module TestLauncher
  def self.launch(input, framework: "guess", run_all: false)
    shell = Shell::Runner.new(log_path: '/tmp/test_launcher.log')
    searcher = Searchers::Git.new(shell)

    command = Frameworks.locate(
      framework_name: framework,
      shell: shell,
      searcher: searcher,
      input: input,
      run_all: run_all
    )

    shell.exec command
  end
end

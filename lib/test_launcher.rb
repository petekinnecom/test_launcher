require "test_launcher/version"

require "test_launcher/base_error"
require "test_launcher/shell/runner"
require "test_launcher/search/git"
require "test_launcher/frameworks"

module TestLauncher
  def self.launch(request)
    shell = Shell::Runner.new(log_path: "/tmp/test_launcher.log")
    searcher = Search::Git.new(shell)

    command = Frameworks.locate(
      request: request,
      shell: shell,
      searcher: searcher
    )

    if command
      shell.exec command
    else
      shell.warn "No tests found."
    end
  rescue BaseError => e
    shell.warn(e)
  end
end

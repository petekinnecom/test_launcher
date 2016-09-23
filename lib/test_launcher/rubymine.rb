require "test_launcher/rubymine/launcher"
require "test_launcher/shell/runner"

TestLauncher::Rubymine::Launcher.new(
  args: ARGV,
  shell: TestLauncher::Shell::Runner.new(log_path: "/dev/null")
).launch

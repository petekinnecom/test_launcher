require "test_launcher/shell/runner"
require "test_launcher/rubymine/launcher"
require "test_launcher/rubymine/request"

# To allow us to simply specify our run configuration as:
#
#  -r test_launcher/rubymine
#
# we need to put the currently executing script in with the args.
#
# Consider the following examples:
#
#   ruby -r test_launcher/rubymine /path/to/test.rb
#
# vs
#
#   ruby -r test_launcher/rubymine spring testunit /path/to/test.rb
#
# In one case, our test to run is $0 and in another case it's an ARGV.
# So we throw them in the same bucket and let the launcher figure it
# out.  It doesn't matter since we will `exec` a new command anyway.

module TestLauncher
  module Rubymine
    def self.launch
      shell = TestLauncher::Shell::Runner.new(log_path: "/dev/null")

      request = Request.new(
        disable_spring: ENV["DISABLE_SPRING"]
      )

      Launcher.new(
        args: [$0].concat(ARGV),
        shell: shell,
        request: request
      ).launch
    end
  end
end

TestLauncher::Rubymine.launch

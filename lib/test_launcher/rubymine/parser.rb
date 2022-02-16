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
    module Parser
      def self.launch(
        shell: TestLauncher::Shell::Runner.new(log_path: "/dev/null"),
        argv: ARGV,
        env: ENV
      )
        request = Request.new(
          disable_spring: env["DISABLE_SPRING"]
        )

        args = [$0].concat(argv).map { |arg|
          if (
            arg.match("minitest_runner.rb") &&
              env.key?("INTELLIJ_IDEA_RUN_CONF_TEST_FILE_PATH")
            )
            arg.sub(
              %r{/.+/minitest_runner.rb['"]?},
              env.fetch("INTELLIJ_IDEA_RUN_CONF_TEST_FILE_PATH")
            )
          elsif (
            arg.match("tunit_or_minitest_in_folder_runner.rb") &&
              env.key?("INTELLIJ_IDEA_RUN_CONF_FOLDER_PATH"))
            arg.sub(
              %r{/.+/tunit_or_minitest_in_folder_runner.rb['"]?},
              File.join(env.fetch("INTELLIJ_IDEA_RUN_CONF_FOLDER_PATH"), "**/*.rb")
            )
          else
            arg
          end
        }

        Launcher.new(
          args: args,
          shell: shell,
          request: request
        ).launch
      end
    end
  end
end

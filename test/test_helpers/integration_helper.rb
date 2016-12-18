require "test_launcher/search/git"
require "test_launcher/shell/runner"

require "test_launcher/cli"
require "test_helpers/mocks"

module TestLauncher
  module IntegrationHelper
    include DefaultMocks

    class IntegrationShell < Shell::Runner
      def exec(string)
        raise "Cannot exec twice!" if defined?(@exec)
        @exec = string
      end

      def recall_exec
        @exec
      end
    end

    private

    def system_path(relative_dir)
      File.join(Dir.pwd, relative_dir)
    end

    def launch(search_string, run_all: false, framework:, name: nil)
      argv = [search_string, "--framework", framework]
      argv << "--all" if run_all
      argv.concat(["--name", name]) if name
      env = {}
      CLI.launch(argv, env, shell: shell_mock)
    end

    def shell_mock
      @shell_mock ||= IntegrationShell.new
    end
  end
end

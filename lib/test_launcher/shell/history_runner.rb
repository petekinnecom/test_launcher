require "delegate"
require "test_launcher/shell/runner"

module TestLauncher
  module Shell
    class HistoryRunner < SimpleDelegator
      # delegates to @shell

      def initialize(shell: Shell::Runner.new, history_path: "/tmp/test_launcher__history")
        @shell = shell
        @history_path = history_path
      end

      def exec(cmd)
        record(cmd)
        @shell.exec(cmd)
      end

      def reexec
        if recall
          @shell.exec(recall)
        else
          warn "Cannot rerun: history file not found or is empty"
          exit
        end
      end

      def record(cmd)
        File.write(@history_path, cmd)
      end

      def recall
        @recall ||= File.file?(@history_path) && File.read(@history_path).chomp
      end

      def __getobj__
        @shell
      end
    end
  end
end

require "test_launcher/shell/color"
require "test_launcher/utils/path"

module TestLauncher
  module Shell
    class Runner
      include Color

      CommandFailureError = Class.new(StandardError)

      attr_accessor :log_path, :queue
      private :log_path, :queue

      def initialize(log_path:)
        @log_path = log_path

        %x{echo "" > #{log_path}}
      end

      def run(cmd, dir: ".")
        command = "cd #{dir} && #{cmd}"
        log(command)

        shell_out(command).split("\n")
      end

      def exec(cmd)
        notify cmd
        Kernel.exec cmd
      end

      def warn(msg)
        log msg
        print "#{red(msg)}\n"
      end

      def notify(msg)
        log msg
        print "#{yellow(msg)}\n"
      end

      def confirm?(question)
        warn "#{question} [Yn]"
        STDIN.gets.strip.downcase != 'n'
      end

      private

      def log(msg)
        %x{echo "#{msg}" >> #{log_path}}
      end

      def shell_out(command)
        %x{ set -o pipefail && #{command} 2>> #{log_path} | tee -a #{log_path} }.chomp
      end

    end
  end
end

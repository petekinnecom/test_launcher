require "test_run/shell/color"
require "test_run/utils/path"

module TestRun
  module Shell
    class Runner
      include Color

      CommandFailureError = Class.new(StandardError)

      attr_accessor :working_directory, :log_path, :queue
      private :working_directory, :log_path, :queue

      def initialize(log_path:, working_directory:)
        @working_directory = working_directory
        @log_path = log_path

        %x{echo "" > #{log_path}}
        Dir.chdir(%x[ git rev-parse --show-toplevel ].chomp)
      end

      def run(cmd, dir: working_directory, &block)
        command = "cd #{Utils::Path.relative_join(dir)} && #{cmd}"
        handle_output_for(command)

        shell_out(command).split("\n")
      end

      def exec(cmd)
        notify cmd
        Kernel.exec cmd
      end

      def warn(msg)
        log msg.to_s
        print "#{red(msg.to_s)}\n"
      end

      def notify(msg)
        log msg.to_s
        print "#{yellow(msg.to_s)}\n"
      end

      def confirm?(question)
        warn "#{question} [Yn]"
        answer = STDIN.gets.strip.downcase
        return answer != 'n'
      end

      private

      def log(msg)
        %x{echo "#{msg.to_s}" >> #{log_path}}
      end

      def handle_output_for(cmd)
        log(cmd)
      end

      def shell_out(command)
        %x{ set -o pipefail && #{command} 2>> #{log_path} | tee -a #{log_path} }.chomp
      end

    end
  end
end

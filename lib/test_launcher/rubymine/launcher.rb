require "test_launcher/frameworks/minitest"
require "test_launcher/shell/runner"

module TestLauncher
  module Rubymine
    class Launcher
      def initialize(args:, shell:, request:)
        @args = args
        @shell = shell
        @request = request
      end

      def launch
        if args.any? {|a| a.match("ruby-debug-ide")}
          shell.puts "test_launcher: hijacking and debugging"

          debug_command = "cd #{test_case.app_root} && ruby -I test #{args.join(" ")}"
          shell.puts debug_command
          shell.exec debug_command
        else
          shell.puts "test_launcher: hijacking and running:"
          shell.puts command

          shell.exec command
        end
      end

      private

      def command
        if test_case.is_example?
          Frameworks::Minitest::Runner.new.single_example(test_case, exact_match: true)
        else
          Frameworks::Minitest::Runner.new.single_file(test_case)
        end
      end

      def test_case
        @test_case ||=
          if args[-1].match("--name=")
            Frameworks::Minitest::TestCase.new(
              file: args[-2],
              example: args[-1][/--name=(.*)/, 1],
              request: request
            )
          else
            Frameworks::Minitest::TestCase.new(
              file: args[-1],
              request: request
            )
          end
      end

      def args
        @args
      end

      def shell
        @shell
      end

      def request
        @request
      end
    end
  end
end

require "test_launcher/frameworks/minitest"
require "test_launcher/shell/runner"

module TestLauncher
  module Rubymine
    class Launcher
      def initialize(args:, shell:)
        @args = args
        @shell = shell
      end

      def launch
        if args.any? {|a| a.match("ruby-debug-ide")}
          test_dir = File.join(test_case.app_root, "test")

          shell.puts "----"
          shell.puts "Using test_launcher to debug"
          shell.puts "Pushing #{test_dir} to $LOAD_PATH"
          shell.puts "----"

          $LOAD_PATH.unshift(test_dir)
          load($0 = args.shift)
        else
          shell.puts "----"
          shell.puts "Using test_launcher to run:"
          shell.puts command
          shell.puts "----"

          shell.exec command
        end
      end

      private

      def command
        if test_case.is_example?
          TestLauncher::Frameworks::Minitest::Runner.new.single_example(test_case, exact_match: true)
        else
          TestLauncher::Frameworks::Minitest::Runner.new.one_or_more_files([test_case])
        end
      end

      def test_case
        @test_case ||=
          if args[-1].match('--name=')
            Frameworks::Minitest::TestCase.new(file: args[-2], example: args[-1][/--name=(.*)/, 1])
          else
            Frameworks::Minitest::TestCase.new(file: args[-1])
          end
      end

      def args
        @args
      end

      def shell
        @shell
      end
    end
  end
end

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
          test_dir = File.join(test_case.test_root)

          shell.puts "test_launcher: RubyMine is debugging"
          shell.puts "test_launcher: Pushing #{test_dir} to $LOAD_PATH"

          $LOAD_PATH.unshift(test_dir)
          load($0 = args.shift)
        else
          shell.puts "test_launcher: hijacking and running:"
          shell.puts command

          shell.exec command
        end
      end

      private

      def command
        if test_case.is_example?
          TestLauncher::Frameworks::Minitest::Runner.new.single_example(test_case, exact_match: true)
        else
          TestLauncher::Frameworks::Minitest::Runner.new.single_file(test_case)
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

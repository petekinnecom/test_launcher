require "test_launcher/frameworks/minitest"
require "test_launcher/shell/runner"

module TestLauncher
  module Rubymine
    # Parsing command line args with regex is not ideal ...¯\_(ツ)_/¯
    TEST_NAME_REGEX = %r{['"]*/?\^?([^/'"\$]*)\$?/?['"]*}

    class Launcher
      def initialize(args:, shell:, request:)
        @args = args
        @shell = shell
        @request = request
      end

      def launch
        if args.any? {|a| a.match("ruby-debug-ide")}
          shell.puts "test_launcher: hijacking and debugging"

          debug_command = (
            if args.first.match(/bash/)
              "cd #{test_cases.first.app_root} && #{args.join(" ")}"
            else
              "cd #{test_cases.first.app_root} && bundle exec ruby -I test #{args.join(" ")}"
            end
          )

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
        if test_cases.count == 1 && test_cases.first.is_example?
          Frameworks::Minitest::Runner.new.single_example(test_cases.first, exact_match: true)
        else
          Frameworks::Minitest::Runner.new.one_or_more_files(test_cases)
        end
      end

      def test_cases
        @test_cases ||=
          if args[-1].match("--name=")
            [
              Frameworks::Minitest::TestCase.new(
              file: args[-2],
              example: args[-1][%r{--name=#{TEST_NAME_REGEX}}, 1],
              request: request
              )
            ]
          elsif args[-2]&.match("--name")
            [
              Frameworks::Minitest::TestCase.new(
                file: args[-3],
                example: args[-1][TEST_NAME_REGEX, 1],
                request: request
              )
            ]
          else
            recursive_test_files = Dir.glob(args[-1])
            recursive_test_files.map{|file|
              Frameworks::Minitest::TestCase.new(
                file: file,
                request: request
              )
            }
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

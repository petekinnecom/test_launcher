require "test_launcher/frameworks/minitest"

module TestLauncher
  class Jetbrains

    def self.launch
      new(ARGV).launch
    end

    def initialize(args)
      @args = args
    end

    def launch
      Dir.chdir('/')
      puts "Using test_launcher to run:"
      puts command
      puts ''
      `echo ''` # sync to stdout or something, I don't know but this makes it display
      exec command
    end

    private

    def command
      if test_case.is_example?
        %{cd #{test_case.app_root} && ruby -I test #{test_case.relative_test_path} --name='#{test_case.example}'}
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
  end
end

TestLauncher::Jetbrains.launch

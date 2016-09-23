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
      if args.any? {|a| a.match("ruby-debug-ide")}
        test_dir = File.join(test_case.app_root.delete("."), "test")

        puts "Using test_launcher to debug"
        puts "Pushing #{test_dir} to $LOAD_PATH"
        puts ""
        `echo ''`

        $LOAD_PATH.unshift(test_dir)
        load($0 = ARGV.shift)
      else
        Dir.chdir('/')
        puts "Using test_launcher to run:"
        puts command
        puts ''
        `echo ''` # sync to stdout or something, I don't know but this makes it display
        exec command
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
  end
end

TestLauncher::Jetbrains.launch

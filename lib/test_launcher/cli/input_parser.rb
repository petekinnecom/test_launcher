require "optparse"

require "test_launcher/version"

require "test_launcher/frameworks/rspec"
require "test_launcher/frameworks/minitest"
require "test_launcher/frameworks/ex_unit"
require "test_launcher/frameworks/generic"
require "test_launcher/cli/options"

module TestLauncher
  module CLI
    class InputParser
      ParseError = Class.new(RuntimeError)

      BANNER = <<-DESC
Find tests and run them by trying to match an individual test or the name of a test file(s).

See full README: https://github.com/petekinnecom/test_launcher

Usage: `test_launcher "search string" [--all]`

VERSION: #{TestLauncher::VERSION}

      DESC

      def initialize(args, env)
        @search_string = args
        @env = env
        @options = {}
        option_parser.parse!(args)
      rescue OptionParser::ParseError
        puts "Invalid arguments"
        puts "----"
        puts option_parser
        exit
      end

      def parsed_options(shell:, searcher:)
        if @search_string.size == 0 && !@options[:rerun]
          puts "Enter a search term"
          puts "----"
          puts option_parser
          exit
        elsif @search_string.size > 0 && @options[:rerun]
          puts "Cannot specify search terms and use --rerun flag"
          puts "----"

          puts option_parser
          exit
        end

        frameworks =
          if @options[:framework] == "rspec"
            [Frameworks::RSpec]
          elsif @options[:framework] == "minitest"
            [Frameworks::Minitest]
          elsif @options[:framework] == "ex_unit"
            [Frameworks::ExUnit]
          elsif @options[:framework] == "generic"
            [Frameworks::Generic]
          else
            [Frameworks::Minitest, Frameworks::RSpec, Frameworks::ExUnit, Frameworks::Generic]
          end

        Options.new(
          search_string: @search_string.join(" "),
          run_all: !!@options[:run_all],
          rerun: !!@options[:rerun],
          disable_spring: @options[:disable_spring] || !!@env["DISABLE_SPRING"],
          example_name: @options[:name],
          frameworks: frameworks,
          shell: shell,
          searcher: searcher,
          wrap: @options[:wrap],
          root_override: @options[:root_override]
        )
      end

      def options
        @options
      end

      private

      def option_parser
        OptionParser.new do |opts|
          opts.banner = BANNER

          opts.on("-a", "--all", "Run all matching tests. Defaults to false.") do
            options[:run_all] = true
          end

          opts.on("-h", "--help", "Prints this help") do
            puts opts
            exit
          end

          opts.on("-v", "--version", "Display the version info") do
            puts TestLauncher::VERSION
            exit
          end

          opts.on("-f", "--framework framework", "The testing framework being used. Valid options: ['minitest', 'rspec', 'ex_unit', 'guess']. Defaults to 'guess'") do |framework|
            options[:framework] = framework
          end

          opts.on("-n", "--name name", "Name of testcase/example to run. This will pass through to the selected framework without verifying that the example actually exists. This option really only exists to work with tooling that will automatically run your tests. You shouldn't have much need for this.") do |name|
            options[:name] = name
          end

          opts.on("--example example", "alias of name") do |example|
            options[:name] = example
          end

          opts.on("-r", "--rerun", "Rerun the previous test. This flag cannot be set when entering search terms") do
            options[:rerun] = true
          end

          opts.on("--disable-spring", "Disable spring. You can also set the env var: DISABLE_SPRING=1") do
            options[:disable_spring] = true
          end

          opts.on("--wrap wrap", "Wrap the test command with a custom wrapper. Use %cmd for substitution location. See README for more info.") do |wrap|
            options[:wrap] = wrap
          end

          opts.on("--root-override override", "Override the path to the app root. See README for more info.") do |override|
            options[:root_override] = override.sub(/\/$/, '') # remove trailing slash if it's there
          end
        end
      end
    end
  end
end

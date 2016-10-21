require "optparse"

require "test_launcher/version"
require "test_launcher/request"

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

      def initialize(args)
        @query = args
        @options = {}
        option_parser.parse!(args)
      rescue OptionParser::ParseError
        puts "Invalid arguments"
        puts "----"
        puts option_parser
        exit
      end

      def request
        if @query.size == 0
          puts option_parser
          exit
        end

        Request.new(
          query: @query.join(" "),
          run_all: @options[:run_all],
          disable_spring: ENV["DISABLE_SPRING"],
          framework: @options[:framework]
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

          opts.on("-f", "--framework framework", "The testing framework being used. Valid options: ['minitest', 'rspec', 'guess']. Defaults to 'guess'") do |framework|
            options[:framework] = framework
          end
        end
      end
    end
  end
end

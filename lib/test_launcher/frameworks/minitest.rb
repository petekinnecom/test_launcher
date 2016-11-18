require "test_launcher/frameworks/base"
require "test_launcher/frameworks/implementation/collection"

module TestLauncher
  module Frameworks
    module Minitest
      #TODO: consolidate with RSpec?
      def self.commandify(run_options:, shell:, searcher:)
        return unless active?

        search_results = Locator.new(run_options, searcher).prioritized_results

        runner = Runner.new

        Implementation::Consolidator.consolidate(search_results, shell, runner)
      end

      def self.active?
        # Do not do this outside of the shell.
        ! Dir.glob("**/test/**/*_test.rb").empty?
      end

      class NamedRequest
        attr_reader :shell, :searcher, :run_options
        def initialize(shell:, searcher:, run_options:)
          @run_options = run_options
          @shell = shell
          @searcher = searcher
        end

        def command
          return unless file

          test_case = TestCase.new(
            file: file,
            example: run_options.example_name,
            request: run_options,
          )

          Runner.new.single_example(test_case, exact_match: true)
        end

        def file
          if potential_files.size == 0
            shell.warn("Could not locate file: #{run_options.query}")
          elsif potential_files.size > 1
            shell.warn("Too many files matched: #{run_options.query}")
          else
            potential_files.first
          end
        end

        def potential_files
          @potential_files ||= searcher.test_files(run_options.query)
        end
      end

      class SearchRequest
        attr_reader :shell, :searcher, :run_options
        def initialize(shell:, searcher:, run_options:)
          @run_options = run_options
          @shell = shell
          @searcher = searcher
        end

        def command
          Minitest.commandify(
            shell: shell,
            searcher: searcher,
            run_options: run_options
          )
        end
      end

      class GenericRequest
        attr_reader :shell, :run_options
        def initialize(shell:, searcher:, run_options:)
          @run_options = run_options
          @shell = shell
          @searcher = searcher
        end

        def command
          request =
            if run_options.example_name
              NamedRequest.new(
                shell: shell,
                searcher: searcher,
                run_options: run_options
              )
            else
              SearchRequest.new(
                shell: shell,
                searcher: searcher,
                run_options: run_options
              )
            end

          request.command
        end

        def searcher
          Minitest::Searcher.new(@searcher)
        end
      end

      class Searcher < Struct.new(:raw_searcher)
        def test_files(query)
          raw_searcher
            .find_files(query)
            .select {|f| f.match(file_name_regex)}
        end

        def grep(regex)
          raw_searcher.grep(regex, file_pattern: file_name_pattern)
        end

        private

        def file_name_regex
          /.*_test\.rb$/
        end

        def file_name_pattern
          "*_test.rb"
        end

        def example_name_regex(query)
          "^\s*def test_.*#{query.sub(/^test_/, "")}.*"
        end
      end

      class Runner < Base::Runner
        def single_example(test_case, exact_match: false)

          name =
            if exact_match
              "--name=#{test_case.example}"
            else
              "--name=/#{test_case.example}/"
            end

          %{cd #{test_case.app_root} && #{test_case.runner} #{test_case.file} #{name}}
        end

        def one_or_more_files(test_cases)
          %{cd #{test_cases.first.app_root} && #{test_cases.first.runner} #{test_cases.map(&:file).join(" ")}}
        end
      end

      class Locator < Base::Locator
        private

        def file_name_regex
          /.*_test\.rb$/
        end

        def file_name_pattern
          "*_test.rb"
        end

        def regex_pattern
          "^\s*def test_.*#{request.query.sub(/^test_/, "")}.*"
        end

        def test_case_class
          TestCase
        end
      end

      class TestCase < Base::TestCase

        def runner
          if spring_enabled?
            "bundle exec spring testunit"
          elsif is_example?
            "bundle exec ruby -I test"
          else
            "bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}'"
          end
        end

        def test_root_dir_name
          "test"
        end

        def spring_enabled?
          # TODO: move ENV reference to options hash
          return false if request.disable_spring?

          [
            "bin/spring",
            "bin/testunit"
          ].any? {|f|
            File.exist?(File.join(app_root, f))
          }
        end

      end
    end
  end
end

require 'shellwords'
require "test_launcher/frameworks/base"
require "test_launcher/base_error"

module TestLauncher
  module Frameworks
    module Minitest
      def self.active?
        # Do not do this outside of the shell.
        `git ls-files '*_test.rb'`.split("\n").any?
      end

      def self.test_case(*a)
        TestCase.new(*a)
      end

      def self.searcher(*a)
        Searcher.new(*a)
      end

      def self.runner(*a)
        Runner.new(*a)
      end

      class Searcher < Base::Searcher
        MultipleByLineMatches = Class.new(BaseError)

        def by_line(file_pattern, line_number)
          files = test_files(file_pattern)
          return [] unless files.any?
          raise multiple_files_error if files.size > 1
          #
          file = files.first
          grep_results = raw_searcher.grep(example_name_regex, file_pattern: file)

          if grep_results.empty?
            # the file exists, but doesn't appear to contain any tests...
            # we'll try to run it anyway
            return [file: file]
          end

          best_result =
            grep_results
              .select {|r| line_number >= r[:line_number]}
              .min_by {|r| line_number - r[:line_number]}

          if best_result
            [{
              file: best_result[:file],
              example_name: best_result[:line].match(/(test_[\w\?]+)/)[1],
              line_number: best_result[:line_number]
            }]
          else
            # line number outside of example. Run whole file
            [{
              file: grep_results.first[:file]
            }]
          end
        end

        private

        def file_name_regex
          /.*_test\.rb$/
        end

        def file_name_pattern
          "*_test.rb"
        end

        def example_name_regex(query="")
          if query.match(/^test_/)
            "^\s*def\s+(#{query}).*"
          else
            "^\s*def\s+test_.*(#{query }).*"
          end
        end

        def multiple_files_error
          MultipleByLineMatches.new(<<-MSG)
It looks like you are running a line number in a test file.

Multiple files have been found that match your query.

This case is not supported for Minitest.

Open an issue on https://github.com/petekinnecom/test_launcher if this is something you have run into at least 3 times. :)
          MSG
        end

      end

      class Runner < Base::Runner
        def by_line_number(test_case)
          if test_case.example
            single_example(test_case, exact_match: true)
          else
            single_file(test_case)
          end
        end

        def single_example(test_case, name: test_case.example, exact_match: false)
          name_arg =
            if exact_match
              name
            else
              "/#{name}/"
            end

          if test_case.spring_enabled?
            %{cd #{test_case.app_root} && #{test_case.example_runner} #{test_case.relative_file} --name='#{name_arg}'}
          else
            %{cd #{test_case.app_root} && #{test_case.example_runner} #{test_case.file} --name='#{name_arg}'}
          end
        end

        def multiple_examples_same_file(test_cases)
          test_case = test_cases.first
          single_example(test_cases.first)
        end

        def multiple_examples_same_root(test_cases)
          %{cd #{test_cases.first.app_root} && bundle exec ruby -I test -r bundler/setup -e "ARGV.push('--name=/#{test_cases.first.example}/')" #{test_cases.map {|tc| "-r #{tc.file}"}.uniq.join(" ")}}
        end

        def one_or_more_files(test_cases)
          if test_cases.first.spring_enabled?
            %{cd #{test_cases.first.app_root} && #{test_cases.first.file_runner} #{test_cases.map(&:relative_file).uniq.join(" ")}}
          else
            %{cd #{test_cases.first.app_root} && #{test_cases.first.file_runner} #{test_cases.map(&:file).uniq.join(" ")}}
          end
        end
      end

      class TestCase < Base::TestCase
        def example_runner
          if spring_enabled?
            "bundle exec spring rails test"
          else
            "bundle exec ruby -I test"
          end
        end

        def file_runner
          if spring_enabled?
            "bundle exec spring rails test"
          else
            "bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}'"
          end
        end

        def test_root_dir_name
          "test"
        end

        def spring_enabled?
          return false if request.disable_spring?
          return true if request.force_spring?

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

require "test_launcher/frameworks/base"

module TestLauncher
  module Frameworks
    module Minitest
      def self.active?
        # Do not do this outside of the shell.
        ! Dir.glob("**/test/**/*_test.rb").empty?
      end

      class BaseRequest
        attr_reader :shell, :searcher, :run_options
        def initialize(shell:, searcher:, run_options:)
          @run_options = run_options
          @shell = shell
          @searcher = searcher
        end

        def command
          raise NotImplementedError
        end

        private

        def test_cases
          raise NotImplementedError
        end

        def runner
          Runner.new
        end

        def one_file?
           file_count == 1
        end

        def file_count
          @file_count ||= test_cases.map {|tc| tc.file }.uniq.size
        end

        def most_recently_edited_test_case
          @most_recently_edited_test_case ||= test_cases.sort_by {|tc| File.mtime(tc.file)}.last
        end

        def build_query(klass)
          klass.new(
            shell: shell,
            searcher: searcher,
            run_options: run_options
          )
        end

        def pluralize(count, singular)
          phrase = "#{count} #{singular}"
          if count == 1
            phrase
          else
            "#{phrase}s"
          end
        end
      end

      class NamedRequest < BaseRequest
        def command
          return unless file

          shell.notify("Found matching test.")
          runner.single_example(test_case, exact_match: true)
        end

        def test_case
          TestCase.new(
            file: file,
            example: run_options.example_name,
            request: run_options,
          )
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

      class MultiQueryRequest < BaseRequest
        def command
          return if test_cases.empty?

          shell.notify("Found #{pluralize(file_count, "file")}.")
          runner.multiple_files(test_cases)
        end

        def test_cases
          @test_cases ||= files.map { |file_path|
            TestCase.new(
              file: file_path,
              request: run_options,
            )
          }
        end

        def files
          if found_files.any? {|files_array| files_array.empty? }
            shell.warn("It looks like you're searching for multiple files, but we couldn't identify them all.")
            []
          else
            found_files.flatten.uniq
          end
        end

        def found_files
          @found_files ||= queries.map {|query|
            searcher.test_files(query)
          }
        end

        def queries
          @queries ||= run_options.query.split(" ")
        end
      end

      class PathQueryRequest < BaseRequest
        def command
          return if test_cases.empty?

          if one_file?
            shell.notify "Found #{pluralize(file_count, "file")}."
            runner.single_file(test_cases.first)
          elsif run_options.run_all?
            shell.notify "Found #{pluralize(file_count, "file")}."
            runner.multiple_files(test_cases)
          else
            shell.notify "Found #{pluralize(file_count, "file")}."
            shell.notify "Running most recently edited. Run with '--all' to run all the tests."
            runner.single_file(most_recently_edited_test_case)
          end
        end

        def test_cases
          @test_cases ||= files_found_by_path.map { |file_path|
            TestCase.new(file: file_path, request: run_options)
          }
        end

        def files_found_by_path
          @files_found_by_path ||= searcher.test_files(run_options.query)
        end
      end

      class ExampleNameQueryRequest < BaseRequest
        def command
          return if test_cases.empty?

          if one_example?
            shell.notify("Found 1 method in 1 file")
            runner.single_example(test_cases.first, exact_match: true)
          elsif one_file?
            shell.notify("Found #{test_cases.size} methods in 1 file")
            runner.single_example(test_cases.first) # it will regex with the query
          elsif run_options.run_all?
            shell.notify "Found #{pluralize(test_cases, "method")} in #{pluralize(file_count, "file")}."
            runner.multiple_files(test_cases)
          else
            shell.notify "Found #{pluralize(test_cases, "method")} in #{pluralize(file_count, "file")}."
            shell.notify "Running most recently edited. Run with '--all' to run all the tests."
            runner.single_example(most_recently_edited_test_case) # let it regex the query
          end
        end

        def test_cases
          @test_cases ||=
            examples_found_by_name.map { |grep_result|
              TestCase.new(
                file: grep_result[:file],
                example: run_options.query,
                request: run_options
              )
            }
        end

        def examples_found_by_name
          @examples_found_by_name ||= searcher.examples(run_options.query)
        end

        def one_example?
          test_cases.size == 1
        end
      end

      class FullRegexRequest < BaseRequest
        def command
          return if test_cases.empty?

          if one_file?
            shell.notify "Found #{pluralize(file_count, "file")}."
            runner.single_file(test_cases.first)
          elsif run_options.run_all?
            shell.notify "Found #{pluralize(file_count, "file")}."
            runner.multiple_files(test_cases)
          else
            test_case = test_cases.sort_by {|tc| File.mtime(tc.file)}.last
            shell.notify "Found #{pluralize(file_count, "file")}."
            shell.notify "Running most recently edited. Run with '--all' to run all the tests."
            runner.single_file(test_case)
          end
        end

        def test_cases
          @test_cases ||=
            files_found_by_full_regex.map { |grep_result|
              TestCase.new(
                file: grep_result[:file],
                request: run_options
              )
            }
        end

        def files_found_by_full_regex
          @files_found_by_full_regex ||= searcher.grep(run_options.query)
        end
      end

      class SingleQueryRequest < BaseRequest
        def command
          [
            path_query,
            example_name_query,
            full_regex_query,
          ]
            .each { |query|
              command = query.command
              return command if command
            }
          nil
        end

        def path_query
          build_query(PathQueryRequest)
        end

        def example_name_query
          build_query(ExampleNameQueryRequest)
        end

        def full_regex_query
          build_query(FullRegexRequest)
        end
      end

      class SearchRequest < BaseRequest
        def command
          _command = multi_query_request.command if run_options.query.split(" ").size > 1
          return _command if _command

          single_query_request.command
        end

        def single_query_request
          build_query(SingleQueryRequest)
        end

        def multi_query_request
          build_query(MultiQueryRequest)
        end
      end

      class GenericRequest
        attr_reader :shell, :run_options
        def initialize(shell:, searcher:, run_options:)
          @run_options = run_options
          @shell = shell
          @raw_searcher = searcher
        end

        def command
          if run_options.example_name
            named_request.command
          else
            search_request.command
          end
        end

        def named_request
          build_query(NamedRequest)
        end

        def search_request
          build_query(SearchRequest)
        end

        def searcher
          Minitest::Searcher.new(@raw_searcher)
        end

        def build_query(klass)
          klass.new(
            shell: shell,
            searcher: searcher,
            run_options: run_options
          )
        end
      end

      class Searcher < Struct.new(:raw_searcher)
        def test_files(query)
          raw_searcher
            .find_files(query)
            .select {|f| f.match(file_name_regex)}
        end

        def examples(query)
          grep(example_name_regex(query))
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

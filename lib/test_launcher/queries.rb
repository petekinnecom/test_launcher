module TestLauncher
  module Queries
    class CommandFinder
      def initialize(request)
        @request = request
      end

      def specified_name
        commandify(SpecifiedNameQuery)
      end

      def multi_search_term
        commandify(MultiTermQuery)
      end

      def by_path
        commandify(PathQuery)
      end

      def example_name
        commandify(ExampleNameQuery)
      end

      def from_full_regex
        commandify(FullRegexQuery)
      end

      def single_search_term
        commandify(SingleTermQuery)
      end

      def full_search
        commandify(SearchQuery)
      end

      def generic_search
        commandify(GenericQuery)
      end

      def line_number
        commandify(LineNumberQuery)
      end

      def request
        @request
      end

      def commandify(klass)
        klass.new(
          request,
          self
        ).command
      end
    end

    class BaseQuery
      attr_reader :shell, :searcher, :request
      def initialize(request, command_finder)
        @request = request
        @command_finder = command_finder
      end

      def command
        raise NotImplementedError
      end

      private

      def test_cases
        raise NotImplementedError
      end

      def runner
        request.runner
      end

      def shell
        request.shell
      end

      def searcher
        request.searcher
      end

      def one_file?
         file_count == 1
      end

      def file_count
        @file_count ||= test_cases.map {|tc| tc.file }.uniq.size
      end

      def most_recently_edited_test_case
        @most_recently_edited_test_case ||= test_cases.sort_by(&:mtime).last
      end

      def pluralize(count, singular)
        phrase = "#{count} #{singular}"
        if count == 1
          phrase
        else
          "#{phrase}s"
        end
      end

      def command_finder
        @command_finder
      end
    end

    class SpecifiedNameQuery < BaseQuery
      def command
        return unless file

        shell.notify("Found matching test.")
        runner.single_example(test_case, exact_match: true)
      end

      def test_case
        request.test_case(
          file: file,
          example: request.example_name,
          request: request,
        )
      end

      def file
        if potential_files.size == 0
          shell.warn("Could not locate file: #{request.search_string}")
        elsif potential_files.size > 1
          shell.warn("Too many files matched: #{request.search_string}")
        else
          potential_files.first
        end
      end

      def potential_files
        @potential_files ||= searcher.test_files(request.search_string)
      end
    end

    class MultiTermQuery < BaseQuery
      def command
        return if test_cases.empty?

        shell.notify("Found #{pluralize(file_count, "file")}.")
        runner.multiple_files(test_cases)
      end

      def test_cases
        @test_cases ||= files.map { |file_path|
          request.test_case(
            file: file_path,
            request: request,
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
        @queries ||= request.search_string.split(" ")
      end
    end

    class PathQuery < BaseQuery
      def command
        return if test_cases.empty?

        if one_file?
          shell.notify "Found #{pluralize(file_count, "file")}."
          runner.single_file(test_cases.first)
        elsif request.run_all?
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
          request.test_case(file: file_path, request: request)
        }
      end

      def files_found_by_path
        @files_found_by_path ||= searcher.test_files(request.search_string)
      end
    end

    class ExampleNameQuery < BaseQuery
      def command
        return if test_cases.empty?

        if one_example?
          shell.notify("Found 1 example in 1 file.")
          runner.single_example(test_cases.first)
        elsif one_file?
          shell.notify("Found #{test_cases.size} examples in 1 file.")
          runner.single_example(test_cases.first) # it will regex with the query
        elsif request.run_all?
          shell.notify "Found #{pluralize(test_cases.size, "example")} in #{pluralize(file_count, "file")}."
          runner.multiple_files(test_cases)
        else
          shell.notify "Found #{pluralize(test_cases.size, "example")} in #{pluralize(file_count, "file")}."
          shell.notify "Running most recently edited. Run with '--all' to run all the tests."
          runner.single_example(most_recently_edited_test_case) # let it regex the query
        end
      end

      def test_cases
        @test_cases ||=
          examples_found_by_name.map { |grep_result|
            request.test_case(
              file: grep_result[:file],
              example: request.search_string,
              request: request
            )
          }
      end

      def examples_found_by_name
        @examples_found_by_name ||= searcher.examples(request.search_string)
      end

      def one_example?
        test_cases.size == 1
      end
    end

    class FullRegexQuery < BaseQuery
      def command
        return if test_cases.empty?

        if one_file?
          shell.notify "Found #{pluralize(file_count, "file")}."
          runner.single_file(test_cases.first)
        elsif request.run_all?
          shell.notify "Found #{pluralize(file_count, "file")}."
          runner.multiple_files(test_cases)
        else
          shell.notify "Found #{pluralize(file_count, "file")}."
          shell.notify "Running most recently edited. Run with '--all' to run all the tests."
          runner.single_file(most_recently_edited_test_case)
        end
      end

      def test_cases
        @test_cases ||=
          files_found_by_full_regex
            .uniq { |grep_result| grep_result[:file] }
            .map { |grep_result|
              request.test_case(
                file: grep_result[:file],
                request: request
              )
            }
      end

      def files_found_by_full_regex
        @files_found_by_full_regex ||= searcher.grep(request.search_string)
      end
    end

    class LineNumberQuery < BaseQuery
      LINE_SPLIT_REGEX = /\A(?<file>.*):(?<line_number>\d+)\Z/

      def command
        match = request.search_string.match(LINE_SPLIT_REGEX)
        return unless match

        search_result = searcher.by_line(match[:file], match[:line_number].to_i)
        return unless search_result

        if search_result[:example_name]
          shell.notify("Found 1 example on line #{search_result[:line_number]}.")
          runner.single_example(request.test_case(file: search_result[:file], example: search_result[:example_name], request: request))
        else
          shell.notify("Found file, but line is not inside an example.")
          runner.single_file(request.test_case(file: search_result[:file], request: request))
        end

      end
    end

    class SingleTermQuery < BaseQuery
      def command
        [
          :by_path,
          :example_name,
          :from_full_regex,
        ]
          .each { |command_type|
            command = command_finder.public_send(command_type)
            return command if command
          }
        nil
      end
    end

    class SearchQuery < BaseQuery
      def command
        command_1 = command_finder.multi_search_term if request.search_string.split(" ").size > 1
        return command_1 if command_1

        command_2 = command_finder.line_number if request.search_string.split(":").size > 1
        return command_2 if command_2

        command_finder.single_search_term
      end
    end

    class GenericQuery < BaseQuery
      def command
        if request.example_name
          command_finder.specified_name
        else
          command_finder.full_search
        end
      end
    end
  end
end

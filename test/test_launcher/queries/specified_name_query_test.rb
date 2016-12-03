require "test_helper"
require "test_helpers/mocks"
require "test_launcher/queries"

module TestLauncher
  module Queries
    class SpecifiedNameQueryTest < TestCase
      include DefaultMocks

      def searcher
        @searcher ||= MockSearcher.new do |m|
          m.impl :test_files do |search_string|
            case search_string
            when "not_found"
              []
            when "multiple_matches"
              ["file_1", "file_2"]
            when "exact_match"
              ["matched_file.rb"]
            else
              raise "can't find #{search_string}"
            end
          end
        end
      end

      def test_command__file_not_found__returns_no_command
        request = MockRequest.new(
          search_string: "not_found",
          shell: default_shell,
          searcher: searcher
        )
        query = SpecifiedNameQuery.new(request, MockCommandFinder.new)

        assert_equal nil, query.command
      end

      def test_command__file_not_found__warns
        request = MockRequest.new(
          search_string: "not_found",
          shell: default_shell,
          searcher: searcher
        )
        SpecifiedNameQuery.new(request, MockCommandFinder.new).command

        assert_equal 1, default_shell.recall(:warn).size
      end

      def test_command__multiple_files_found
        request = MockRequest.new(
          search_string: "multiple_matches",
          shell: default_shell,
          searcher: searcher
        )
        query = SpecifiedNameQuery.new(request, MockCommandFinder.new)

        assert_equal nil, query.command
      end

      def test_command__multiple_files_found__warns
        request = MockRequest.new(
          search_string: "multiple_matches",
          shell: default_shell,
          searcher: searcher
        )
        SpecifiedNameQuery.new(request, MockCommandFinder.new).command

        assert_equal 1, default_shell.recall(:warn).size
      end

      def test_command__exact_match__command_is_single_example
        runner = MockRunner.new(
          single_example: :single_example
        )

        test_case = MockTestCase.new

        request = MockRequest.new(
          search_string: "exact_match",
          example_name: "example_name",
          test_case: test_case,
          shell: default_shell,
          runner: runner,
          searcher: searcher
        )
        command = SpecifiedNameQuery.new(request, MockCommandFinder.new).command

        expected_runner_args = [
          test_case,
          exact_match: true
        ]

        assert_includes runner.recall(:single_example), expected_runner_args
        assert_equal :single_example, command
      end

      def test_command__exact_match__creates_example_test_case
        runner = MockRunner.new(
          single_example: :single_example
        )

        test_case = MockTestCase.new

        request = MockRequest.new(
          search_string: "exact_match",
          example_name: "example_name",
          test_case: test_case,
          shell: default_shell,
          runner: runner,
          searcher: searcher
        )
        command = SpecifiedNameQuery.new(request, MockCommandFinder.new).command

        expected_test_case_args = [
          file: "matched_file.rb",
          example: "example_name",
          request: request
        ]

        assert_includes request.recall(:test_case), expected_test_case_args
      end
    end
  end
end

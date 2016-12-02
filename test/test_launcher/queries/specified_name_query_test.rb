require "test_helper"
require "test_launcher/queries"

module TestLauncher
  module Queries
    class SpecifiedNameQueryTest < TestCase

      class MockSearcher
        def test_files(search_string)
          case search_string
          when "no_matches"
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

      class BaseMock
        UnmockedMethodError = Class.new(StandardError)

        def initialize(attrs={})
          @attrs = attrs
          @calls = {}
        end

        def method_missing(method_name, *args)
          (@calls[method_name] ||= []) << args
          return @attrs[method_name] if @attrs[method_name]

          raise UnmockedMethodError, "#{method_name} is not mocked"
        end

        def recall(method_name)
          @calls[method_name]
        end
      end

      class MockShell < BaseMock
        def warn(*args)
          (@calls[:warn] ||= []) << args
          nil
        end

        def notify(*args)
          (@calls[:notify] ||= []) << args
          nil
        end
      end

      class MockRequest < BaseMock
        def searcher
          MockSearcher.new
        end
      end

      class MockCommandFinder
      end

      def test_command__file_not_found__returns_no_command
        request = MockRequest.new(
          search_string: "no_matches",
          shell: MockShell.new,
          runner: BaseMock.new
        )
        query = SpecifiedNameQuery.new(request, MockCommandFinder.new)

        assert_equal nil, query.command
      end

      def test_command__file_not_found__warns
        shell = MockShell.new
        request = MockRequest.new(
          search_string: "no_matches",
          shell: shell,
          runner: BaseMock.new
        )
        SpecifiedNameQuery.new(request, MockCommandFinder.new).command

        assert_equal 1, shell.recall(:warn).size
      end

      def test_command__multiple_files_found
        request = MockRequest.new(
          search_string: "multiple_matches",
          shell: MockShell.new
        )
        query = SpecifiedNameQuery.new(request, MockCommandFinder.new)

        assert_equal nil, query.command
      end

      def test_command__multiple_files_found__warns
        shell = MockShell.new
        request = MockRequest.new(
          search_string: "multiple_matches",
          shell: shell
        )
        SpecifiedNameQuery.new(request, MockCommandFinder.new).command

        assert_equal 1, shell.recall(:warn).size
      end

      def test_command__exact_match__command_is_single_example
        shell = MockShell.new
        mock_runner = BaseMock.new(
          single_example: :single_example
        )

        request = MockRequest.new(
          search_string: "exact_match",
          example_name: "example_name",
          test_case: :test_case,
          shell: shell,
          runner: mock_runner
        )
        command = SpecifiedNameQuery.new(request, MockCommandFinder.new).command

        expected_test_case_args = [
          file: "matched_file.rb",
          example: "example_name",
          request: request
        ]

        expected_runner_args = [
          :test_case,
          exact_match: true
        ]

        assert_includes mock_runner.recall(:single_example), expected_runner_args
        assert_includes request.recall(:test_case), expected_test_case_args
        assert_equal :single_example, command
      end

      def test_command__exact_match__creates_example_test_case
        shell = MockShell.new
        mock_runner = BaseMock.new(
          single_example: :single_example
        )

        request = MockRequest.new(
          search_string: "exact_match",
          example_name: "example_name",
          test_case: :test_case,
          shell: shell,
          runner: mock_runner
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

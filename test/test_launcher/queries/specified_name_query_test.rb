require "test_helper"
require "test_launcher/queries"

module TestLauncher
  module Queries
    class SpecifiedNameQueryTest < TestCase

      class Mock
        UnmockedMethodError = Class.new(StandardError)

        def self.stub(method_name)
          define_method method_name do |*args|
            record_call(method_name, args)
            yield(*args) if block_given?
          end
        end

        def initialize(attrs={})
          @attrs = attrs
          @calls = {}
        end

        def recall(method_name)
          @calls[method_name]
        end

        private

        def method_missing(method_name, *args)
          record_call(method_name, args)

          if @attrs.key?(method_name)
            @attrs[method_name]
          else
            raise UnmockedMethodError, "#{method_name} is not mocked"
          end
        end

        def record_call(method_name, args)
          (@calls[method_name] ||= []) << args
        end
      end

      class MockSearcher < Mock
        stub :test_files do |search_string|
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

      class MockShell < Mock
        stub :warn
        stub :notify
        stub :puts
      end

      class MockCommandFinder < Mock
      end

      def setup
        @shell = MockShell.new
      end

      def test_command__file_not_found__returns_no_command
        request = Mock.new(
          search_string: "no_matches",
          shell: @shell,
          runner: Mock.new,
          searcher: MockSearcher.new
        )
        query = SpecifiedNameQuery.new(request, MockCommandFinder.new)

        assert_equal nil, query.command
      end

      def test_command__file_not_found__warns
        request = Mock.new(
          search_string: "no_matches",
          shell: @shell,
          runner: Mock.new,
          searcher: MockSearcher.new
        )
        SpecifiedNameQuery.new(request, MockCommandFinder.new).command

        assert_equal 1, @shell.recall(:warn).size
      end

      def test_command__multiple_files_found
        request = Mock.new(
          search_string: "multiple_matches",
          shell: @shell,
          searcher: MockSearcher.new
        )
        query = SpecifiedNameQuery.new(request, MockCommandFinder.new)

        assert_equal nil, query.command
      end

      def test_command__multiple_files_found__warns
        request = Mock.new(
          search_string: "multiple_matches",
          shell: @shell,
          searcher: MockSearcher.new
        )
        SpecifiedNameQuery.new(request, MockCommandFinder.new).command

        assert_equal 1, @shell.recall(:warn).size
      end

      def test_command__exact_match__command_is_single_example
        mock_runner = Mock.new(
          single_example: :single_example
        )

        request = Mock.new(
          search_string: "exact_match",
          example_name: "example_name",
          test_case: :test_case,
          shell: @shell,
          runner: mock_runner,
          searcher: MockSearcher.new
        )
        command = SpecifiedNameQuery.new(request, MockCommandFinder.new).command

        expected_runner_args = [
          :test_case,
          exact_match: true
        ]

        assert_includes mock_runner.recall(:single_example), expected_runner_args
        assert_equal :single_example, command
      end

      def test_command__exact_match__creates_example_test_case
        mock_runner = Mock.new(
          single_example: :single_example
        )

        request = Mock.new(
          search_string: "exact_match",
          example_name: "example_name",
          test_case: :test_case,
          shell: @shell,
          runner: mock_runner,
          searcher: MockSearcher.new
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

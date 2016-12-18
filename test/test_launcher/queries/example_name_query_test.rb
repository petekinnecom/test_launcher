require "test_helper"
require "test_helpers/mocks"
require "test_launcher/queries"

module TestLauncher
  module Queries
    class ExampleNameQueryTest < TestCase
      include DefaultMocks

      def searcher
        @searcher ||= MockSearcher.new do |m|
          m.impl :examples do |search_string|
            case search_string
            when "not_found"
              []
            when "one_example"
              [file: "file_1", line: "unused"]
            when "multiple_examples__one_file"
              [
                {file: "file_2", line: "unused"},
                {file: "file_2", line: "unused"},
              ]
            when "multiple_examples__multiple_files"
              [
                {file: "file_3", line: "unused"},
                {file: "file_4", line: "unused"},
              ]
            else
              raise "unmocked search_string: #{search_string}"
            end
          end
        end
      end

      def create_mock_request(**attrs)
        MockRequest.new(**attrs) do |m|
          m.impl(:test_case) do |file:, example:, request:|
            case file
            when "file_1"
              file_1_test_case
            when "file_2"
              file_2_test_case
            when "file_3"
              file_3_test_case
            when "file_4"
              file_4_test_case
            else
              raise "unmocked file: #{file}"
            end
          end
        end
      end

      def file_1_test_case
        @file_1_test_case ||= MockTestCase.new(file: "file_1", mtime: Time.now - 1)
      end

      def file_2_test_case
        @file_2_test_case ||= MockTestCase.new(file: "file_2", mtime: Time.now - 2)
      end

      def file_3_test_case
        @file_3_test_case ||= MockTestCase.new(file: "file_3", mtime: Time.now - 3)
      end

      def file_4_test_case
        @file_4_test_case ||= MockTestCase.new(file: "file_4", mtime: Time.now - 4)
      end

      def test_command__example_not_found__returns_nil
        request = create_mock_request(
          search_string: "not_found",
          searcher: searcher
        )

        command = ExampleNameQuery.new(request, default_command_finder).command

        assert_equal nil, command
      end

      def test_command__one_example_found
        request = create_mock_request(
          search_string: "one_example",
          searcher: searcher,
          runner: default_runner,
          shell: default_shell
        )

        command = ExampleNameQuery.new(request, default_command_finder).command

        assert_equal [[file_1_test_case]], default_runner.recall(:single_example)

        assert_equal "single_example_return", command
      end

      def test_command__one_example_found__notifies
        request = create_mock_request(
          search_string: "one_example",
          searcher: searcher,
          runner: default_runner,
          shell: default_shell
        )

        command = ExampleNameQuery.new(request, default_command_finder).command

        messages = [
          ["Found 1 example in 1 file."],
        ]
        assert_equal messages, default_shell.recall(:notify)
      end

      def test_command__multiple_examples__one_file
        request = create_mock_request(
          search_string: "multiple_examples__one_file",
          searcher: searcher,
          runner: default_runner,
          shell: default_shell
        )

        command = ExampleNameQuery.new(request, default_command_finder).command

        assert_equal [[file_2_test_case]], default_runner.recall(:single_example)

        assert_equal "single_example_return", command
      end

      def test_command__multiple_examples__one_file__notifies
        request = create_mock_request(
          search_string: "multiple_examples__one_file",
          searcher: searcher,
          runner: default_runner,
          shell: default_shell
        )

        command = ExampleNameQuery.new(request, default_command_finder).command

        messages = [
          ["Found 2 examples in 1 file."],
        ]
        assert_equal messages, default_shell.recall(:notify)
      end

      def test_command__multiple_examples__multiple_files__no_all
        request = create_mock_request(
          search_string: "multiple_examples__multiple_files",
          searcher: searcher,
          runner: default_runner,
          shell: default_shell,
          run_all?: false
        )

        command = ExampleNameQuery.new(request, default_command_finder).command

        assert_equal [[file_3_test_case]], default_runner.recall(:single_example)

        assert_equal "single_example_return", command
      end

      def test_command__multiple_examples__multiple_files__no_all__notifies
        request = create_mock_request(
          search_string: "multiple_examples__multiple_files",
          searcher: searcher,
          runner: default_runner,
          shell: default_shell,
          run_all?: false
        )

        command = ExampleNameQuery.new(request, default_command_finder).command

        messages = [
          ["Found 2 examples in 2 files."],
          ["Running most recently edited. Run with '--all' to run all the tests."],
        ]
        assert_equal messages, default_shell.recall(:notify)
      end

      def test_command__multiple_examples__multiple_files__all
        request = create_mock_request(
          search_string: "multiple_examples__multiple_files",
          searcher: searcher,
          runner: default_runner,
          shell: default_shell,
          run_all?: true
        )

        command = ExampleNameQuery.new(request, default_command_finder).command

        assert_equal [[[file_3_test_case, file_4_test_case]]], default_runner.recall(:multiple_files)

        assert_equal "multiple_files_return", command
      end

      def test_command__multiple_examples__multiple_files__all__notifies
        request = create_mock_request(
          search_string: "multiple_examples__multiple_files",
          searcher: searcher,
          runner: default_runner,
          shell: default_shell,
          run_all?: true
        )

        command = ExampleNameQuery.new(request, default_command_finder).command

        messages = [
          ["Found 2 examples in 2 files."],
        ]
        assert_equal messages, default_shell.recall(:notify)
      end

    end
  end
end

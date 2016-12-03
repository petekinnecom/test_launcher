require "test_helper"
require "test_helpers/mocks"
require "test_launcher/queries"

module TestLauncher
  module Queries
    class PathQueryTest < TestCase
      include DefaultMocks

      def searcher
        @searcher ||= MockSearcher.new do |m|
          m.impl :test_files do |search_string|
            case search_string
            when "not_found"
              []
            when "one_file"
              ["file_1"]
            when "multiple_files"
              ["file_2", "file_3", "file_4"]
            else
              raise "unmocked search_string: #{search_string}"
            end
          end
        end
      end

      def create_mock_request(**attrs)
        MockRequest.new(**attrs) do |m|
          m.impl(:test_case) do |file:, request:|
            case file
            when "file_1"
              normal_test_case
            when "file_2"
              old_test_case
            when "file_3"
              older_test_case
            when "file_4"
              new_test_case
            else
              raise "unmocked file: #{file}"
            end
          end
        end
      end

      def normal_test_case
        @normal_test_case ||= MockTestCase.new(file: "file_1")
      end

      def old_test_case
        @old_test_case ||= MockTestCase.new(file: "file_2", mtime: Time.now - 1000)
      end

      def older_test_case
        @older_test_case ||= MockTestCase.new(file: "file_3", mtime: Time.now - 10000)
      end

      def new_test_case
        @new_test_case ||= MockTestCase.new(file: "file_4", mtime: Time.now)
      end

      def test_command__file_not_found__returns_nil
        request = create_mock_request(
          search_string: "not_found",
          searcher: searcher
        )

        command = PathQuery.new(request, default_command_finder).command

        assert_equal nil, command
      end

      def test_command__file_not_found__does_not_warn
        request = create_mock_request(
          search_string: "not_found",
          searcher: searcher
        )

        command = PathQuery.new(request, default_command_finder).command

        assert default_shell.recall(:warn).empty?
      end

      def test_command__one_file_found__runs_single_file
        request = create_mock_request(
          search_string: "one_file",
          shell: default_shell,
          searcher: searcher,
          runner: default_runner
        )

        command = PathQuery.new(request, default_command_finder).command

        assert_equal [[normal_test_case]], default_runner.recall(:single_file)
        assert_equal "single_file_return", command
      end

      def test_command__one_file_found__has_correct_test_case
        request = create_mock_request(
          search_string: "one_file",
          shell: default_shell,
          searcher: searcher,
          runner: default_runner
        )

        expected_test_case_args = [file: "file_1", request: request]

        command = PathQuery.new(request, default_command_finder).command

        assert_equal [expected_test_case_args], request.recall(:test_case)
      end

      def test_command__one_file_found__notifies
        request = create_mock_request(
          search_string: "one_file",
          shell: default_shell,
          searcher: searcher,
          runner: default_runner
        )

        command = PathQuery.new(request, default_command_finder).command

        assert_equal [["Found 1 file."]], default_shell.recall(:notify)
      end

      def test_command__multiple_files_found__no_all__runs_single_file
        request = create_mock_request(
          search_string: "multiple_files",
          shell: default_shell,
          searcher: searcher,
          runner: default_runner,
          run_all?: false
        )

        command = PathQuery.new(request, default_command_finder).command

        assert_equal [[new_test_case]], default_runner.recall(:single_file)
        assert_equal "single_file_return", command
      end

      def test_command__multiple_files_found__no_all__notifies
        request = create_mock_request(
          search_string: "multiple_files",
          shell: default_shell,
          searcher: searcher,
          runner: default_runner,
          run_all?: false
        )

        command = PathQuery.new(request, default_command_finder).command

        messages = [
          ["Found 3 files."],
          ["Running most recently edited. Run with '--all' to run all the tests."]
        ]
        assert_equal messages, default_shell.recall(:notify)
      end

      def test_command__multiple_files_found__all__runs_single_file
        request = create_mock_request(
          search_string: "multiple_files",
          shell: default_shell,
          searcher: searcher,
          runner: default_runner,
          run_all?: true
        )

        command = PathQuery.new(request, default_command_finder).command

        assert_equal [[[old_test_case, older_test_case, new_test_case]]], default_runner.recall(:multiple_files)
        assert_equal "multiple_files_return", command
      end

      def test_command__multiple_files_found__all__notifies
        request = create_mock_request(
          search_string: "multiple_files",
          shell: default_shell,
          searcher: searcher,
          runner: default_runner,
          run_all?: true
        )

        command = PathQuery.new(request, default_command_finder).command

        messages = [
          ["Found 3 files."]
        ]
        assert_equal messages, default_shell.recall(:notify)
      end
    end
  end
end

require "test_helper"
require "test_helpers/mocks"
require "test_launcher/queries"

module TestLauncher
  module Queries
    class FullRegexQueryTest < TestCase
      include DefaultMocks

      def searcher
        @searcher ||= MockSearcher.new do |m|
          m.impl :grep do |regex|
            case [regex]
            when ["not_found"]
              []
            when ["single"]
              [{file: "single_test.rb", line: "matches single", line_number: 17}]
            when ["multiple_same_file"]
              [
                {file: "multiple_test.rb", line: "matches multiple_same_file", line_number: 17},
                {file: "multiple_test.rb", line: "matches multiple_same_file", line_number: 29},
                {file: "multiple_test.rb", line: "matches multiple_same_file", line_number: 31},
              ]
            when ["multiple_different_files"]
              [
                {file: "multiple_1_test.rb", line: "matches multiple_different_files", line_number: 17},
                {file: "multiple_2_test.rb", line: "matches multiple_different_files", line_number: 29},
              ]
            else
              raise "unmocked search_string: #{file}, #{line_number}"
            end
          end
        end
      end

      def create_mock_request(**attrs)
        MockRequest.new(**attrs) do |m|
          m.impl(:test_case) do |file:, example: nil, request:|
            case [file, example]
            when ["single_test.rb", nil]
              single_file_test_case
            when ["multiple_test.rb", nil]
              multiple_test_case
            when ["multiple_1_test.rb", nil]
              multiple_1_test_case
            when ["multiple_2_test.rb", nil]
              multiple_2_test_case
            else
              raise "unmocked file: #{file}"
            end
          end
        end
      end

      def single_file_test_case
        @single_file_test_case ||= MockTestCase.new(file: "single_test.rb")
      end

      def multiple_test_case
        @multiple_test_case ||= MockTestCase.new(file: "multiple_test.rb")
      end

      def multiple_1_test_case
        @multiple_1_test_case ||= MockTestCase.new(file: "multiple_1_test.rb", mtime: Time.now - 3)
      end

      def multiple_2_test_case
        @multiple_2_test_case ||= MockTestCase.new(file: "multiple_2_test.rb", mtime: Time.now - 2)
      end

      def test_command__regex_not_found
        request = create_mock_request(
          search_string: "not_found",
          searcher: searcher
        )

        command = FullRegexQuery.new(request, default_command_finder).command
        assert_equal nil, command
      end

      def test_command__single_match
        request = create_mock_request(
          search_string: "single",
          searcher: searcher,
          runner: default_runner,
          shell: default_shell
        )

        command = FullRegexQuery.new(request, default_command_finder).command

        assert_equal [[single_file_test_case]], default_runner.recall(:single_file)

        assert_equal "single_file_return", command
      end

      def test_command__multiple_matches_same_file
        request = create_mock_request(
          search_string: "multiple_same_file",
          searcher: searcher,
          runner: default_runner,
          shell: default_shell
        )

        command = FullRegexQuery.new(request, default_command_finder).command

        assert_equal [[multiple_test_case]], default_runner.recall(:single_file)

        assert_equal "single_file_return", command
      end

      def test_command__multiple_matches_different_files__no_all
        request = create_mock_request(
          search_string: "multiple_different_files",
          searcher: searcher,
          runner: default_runner,
          shell: default_shell,
          run_all?: false
        )

        command = FullRegexQuery.new(request, default_command_finder).command

        assert_equal [[multiple_2_test_case]], default_runner.recall(:single_file)

        assert_equal "single_file_return", command
      end

      def test_command__multiple_matches_different_files__all
        request = create_mock_request(
          search_string: "multiple_different_files",
          searcher: searcher,
          runner: default_runner,
          shell: default_shell,
          run_all?: true
        )

        command = FullRegexQuery.new(request, default_command_finder).command

        assert_equal [[[multiple_1_test_case, multiple_2_test_case]]], default_runner.recall(:multiple_files)

        assert_equal "multiple_files_return", command
      end
    end
  end
end

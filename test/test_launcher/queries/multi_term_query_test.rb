require "test_helper"
require "test_helpers/mocks"
require "test_launcher/queries"

module TestLauncher
  module Queries
    class MultiTermQueryTest < TestCase
      include DefaultMocks

      def searcher
        @searcher ||= MockSearcher.new do |m|
          m.impl :test_files do |search_string|
            case search_string
            when "not_found"
              []
            when "file_1"
              ["file_1"]
            when "file_2"
              ["file_2"]
            when "files"
              ["file_3", "file_4"]
            else
              raise "can't find #{search_string}"
            end
          end
        end
      end

      def test_command__finds_files_for_0_of_2_terms_asdf
        request = MockRequest.new(
          search_string: "not_found not_found",
          shell: default_shell,
          runner: default_runner,
          searcher: searcher
        )
        command = MultiTermQuery.new(request, default_command_finder).command

        assert_equal nil, command
      end

      def test_command__finds_files_for_0_of_2_terms__warns
        request = MockRequest.new(
          search_string: "not_found not_found",
          shell: default_shell,
          runner: default_runner,
          searcher: searcher
        )
        command = MultiTermQuery.new(request, default_command_finder).command

        assert_equal 1, default_shell.recall(:warn).size
      end

      def test_command__finds_files_for_1_of_2_terms
        request = MockRequest.new(
          search_string: "file_1 not_found",
          shell: default_shell,
          runner: default_runner,
          searcher: searcher
        )
        command = MultiTermQuery.new(request, default_command_finder).command

        assert_equal nil, command
      end

      def test_command__finds_files_for_1_of_2_terms__warns
        request = MockRequest.new(
          search_string: "file_1 not_found",
          shell: default_shell,
          searcher: searcher
        )
        command = MultiTermQuery.new(request, default_command_finder).command

        assert_equal 1, default_shell.recall(:warn).size
      end

      def test_command__finds_files_for_2_of_2_terms
        test_case = MockTestCase.new(file: "file")
        runner = MockRunner.new(
          multiple_files: :multiple_files
        )
        request = MockRequest.new(
          search_string: "file_1 file_2",
          shell: default_shell,
          runner: runner,
          searcher: searcher,
          test_case: test_case
        )
        command = MultiTermQuery.new(request, default_command_finder).command

        assert_equal [[[test_case, test_case]]], runner.recall(:multiple_files)
        assert_equal :multiple_files, command
      end

      def test_command__finds_files_for_2_of_2_terms__correct_test_cases
        test_case = MockTestCase.new(file: "file")
        runner = MockRunner.new(
          multiple_files: :multiple_files
        )
        request = MockRequest.new(
          search_string: "file_1 file_2",
          shell: default_shell,
          runner: runner,
          searcher: searcher,
          test_case: test_case
        )
        command = MultiTermQuery.new(request, default_command_finder).command

        expected_test_cases = [
          [file: "file_1", request: request],
          [file: "file_2", request: request],
        ]
        assert_equal expected_test_cases, request.recall(:test_case)
      end

      def test_command__finds_files_for_2_of_2_terms__extra_files_found
        test_case = MockTestCase.new(file: "file")
        runner = MockRunner.new(
          multiple_files: :multiple_files
        )
        request = MockRequest.new(
          search_string: "file_1 files",
          shell: default_shell,
          runner: runner,
          searcher: searcher,
          test_case: test_case
        )
        command = MultiTermQuery.new(request, default_command_finder).command
        expected_test_cases = [
          [file: "file_1", request: request],
          [file: "file_3", request: request],
          [file: "file_4", request: request],
        ]
        assert_equal expected_test_cases, request.recall(:test_case)
      end
    end
  end
end

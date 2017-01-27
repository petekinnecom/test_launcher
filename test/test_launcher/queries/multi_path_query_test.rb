require "test_helper"
require "test_helpers/mocks"
require "test_launcher/queries"

module TestLauncher
  module Queries
    class MultiPathQueryTest < TestCase
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

      def create_mock_request(**attrs)
        MockRequest.new(**attrs) do |m|
          m.impl(:test_case) do |file:, example: nil, request:|
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


      def test_command__finds_files_for_0_of_2_terms_asdf
        request = create_mock_request(
          search_string: "not_found not_found",
          shell: default_shell,
          runner: default_runner,
          searcher: searcher
        )
        command = MultiPathQuery.new(request, default_command_finder).command

        assert_equal nil, command
      end

      def test_command__finds_files_for_1_of_2_terms
        request = create_mock_request(
          search_string: "file_1 not_found",
          shell: default_shell,
          runner: default_runner,
          searcher: searcher
        )
        command = MultiPathQuery.new(request, default_command_finder).command

        assert_equal nil, command
      end

      def test_command__finds_files_for_1_of_2_terms__warns
        request = create_mock_request(
          search_string: "file_1 not_found",
          shell: default_shell,
          searcher: searcher
        )
        command = MultiPathQuery.new(request, default_command_finder).command

        assert_equal 1, default_shell.recall(:warn).size
      end

      def test_command__finds_files_for_2_of_2_terms
        request = create_mock_request(
          search_string: "file_1 file_2",
          shell: default_shell,
          runner: default_runner,
          searcher: searcher,
        )
        command = MultiPathQuery.new(request, default_command_finder).command

        assert_equal [[[file_1_test_case, file_2_test_case]]], default_runner.recall(:multiple_files)
        assert_equal "multiple_files_return", command
      end

      def test_command__finds_files_for_2_of_2_terms__extra_files_found
        request = create_mock_request(
          search_string: "file_1 files",
          shell: default_shell,
          runner: default_runner,
          searcher: searcher,
        )
        command = MultiPathQuery.new(request, default_command_finder).command
        assert_equal [[[file_1_test_case, file_3_test_case, file_4_test_case]]], default_runner.recall(:multiple_files)
        assert_equal "multiple_files_return", command
      end
    end
  end
end

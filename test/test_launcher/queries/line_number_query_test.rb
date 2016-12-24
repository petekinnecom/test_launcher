require "test_helper"
require "test_helpers/mocks"
require "test_launcher/queries"

module TestLauncher
  module Queries
    class LineNumberQueryTest < TestCase
      include DefaultMocks

      def searcher
        @searcher ||= MockSearcher.new do |m|
          m.impl :by_line do |file, line_number|
            case [file, line_number]
            when ["not_found", 1]
              nil
            when ["found", 17]
              {file: "found", example_name: "test_example", line_number: 14}
            when ["found", 1]
              {file: "found"}
            when ["found", 9999]
              raise "invalid line number"
            when ["multiple", 1]
              raise "multiple files matched with line query"
            else
              raise "unmocked search_string: #{file}, #{line_number}"
            end
          end
        end
      end

      def create_mock_request(**attrs)
        MockRequest.new(**attrs) do |m|
          m.impl(:test_case) do |file:, example: nil, request:, line_number: nil|
            case [file, example]
            when ["found", nil]
              whole_file_test_case
            when ["found", "test_example"]
              example_name_test_case
            else
              raise "unmocked file: #{file}"
            end
          end
        end
      end

      def whole_file_test_case
        @whole_file_test_case ||= MockTestCase.new(file: "found")
      end

      def example_name_test_case
        @example_name_test_case ||= MockTestCase.new(file: "found", example_name: "test_example")
      end

      def test_command__file_not_found
        request = create_mock_request(
          search_string: "not_found:1",
          searcher: searcher
        )

        command = LineNumberQuery.new(request, default_command_finder).command
        assert_equal nil, command
      end

      def test_command__search_string_does_not_have_colon
        request = create_mock_request(
          search_string: "not_found",
          searcher: searcher
        )

        command = LineNumberQuery.new(request, default_command_finder).command

        assert_equal nil, command
      end

      def test_command__file_found__line_number_not_in_example
        request = create_mock_request(
          search_string: "found:1",
          searcher: searcher,
          runner: default_runner,
          shell: default_shell
        )

        command = LineNumberQuery.new(request, default_command_finder).command

        assert_equal [[whole_file_test_case]], default_runner.recall(:single_file)

        assert_equal "single_file_return", command
      end


      def test_command__file_found__line_number_inside_example
        request = create_mock_request(
          search_string: "found:17",
          searcher: searcher,
          runner: default_runner,
          shell: default_shell
        )

        command = LineNumberQuery.new(request, default_command_finder).command

        assert_equal [[example_name_test_case]], default_runner.recall(:single_example)

        assert_equal "single_example_return", command
      end
    end
  end
end

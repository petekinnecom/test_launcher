require "test_helper"
require "test_launcher/frameworks/minitest"
require "test_launcher/cli/request"
require "test_launcher/base_error"

module TestLauncher
  module Frameworks
    class MinitestTest < TestCase
      # integration test

      class DummyRequest < CLI::Request
      end

      class DummySearcher
        def find_files(pattern)
          if pattern == "no_matches_test.rb"
            []
          else
            ["/path/to/test/file_test.rb"]
          end
        end
      end

      def test_commandify__returns_nil_if_not_active
        Minitest.expects(:active?).returns(false)

        command = Minitest.commandify(
          request: nil,
          shell: nil,
          searcher: nil
        )

        assert_equal nil, command
      end

      def test_commandify__integration__locates
        Minitest.expects(:active?).returns(true)

        request = DummyRequest.new(query: "file_test.rb")
        searcher = DummySearcher.new

        command = Minitest.commandify(
          request: request,
          shell: dummy_shell,
          searcher: searcher
        )

        expected_test_case = Minitest::TestCase.new(
          file: "/path/to/test/file_test.rb",
          request: request
        )
        expected_command = Minitest::Runner.new.single_file(expected_test_case)

        assert_equal expected_command, command
      end

      def test_commandify__integration__passes_through
        Minitest.expects(:active?).returns(true)

        request = DummyRequest.new(query: "/path/to/test/file_test.rb", example_name: "example_name")
        searcher = DummySearcher.new

        command = Minitest.commandify(
          request: request,
          shell: dummy_shell,
          searcher: searcher
        )

        expected_test_case = Minitest::TestCase.new(
          file: "/path/to/test/file_test.rb",
          request: request,
          example: "example_name"
        )
        expected_command = Minitest::Runner.new.single_example(expected_test_case, exact_match: true)

        assert_equal expected_command, command
      end

      def test_commandify__integration__pass_through__raises_if_no_results
        Minitest.expects(:active?).returns(true)

        request = DummyRequest.new(query: "no_matches_test.rb", example_name: "example_name")
        searcher = DummySearcher.new

        error = assert_raises BaseError do
          Minitest.commandify(
            request: request,
            shell: dummy_shell,
            searcher: searcher
          )
        end

        assert_equal "The specified test file could not be found.", error.message
      end
    end
  end
end

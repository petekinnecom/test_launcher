require "test_helper"
require "test_launcher/cli/input_parser"

module TestLauncher
  module CLI
    class InputParserTest < TestCase

      def test_request__defaults
        requests = parse("a_string", {})

        assert_equal "a_string", requests.first.first.search_string
        assert_equal false, requests.first.first.run_all?
        assert_equal false, requests.first.first.disable_spring?
        assert_equal nil, requests.first.first.example_name
      end

      def test_request__all
        requests = parse("a_string --all", {})

        assert_equal "a_string", requests.first.first.search_string
        assert_equal true, requests.first.first.run_all?
      end

      def test_request__disable_spring
        requests = parse("a_string", {"DISABLE_SPRING" => "1"})

        assert_equal "a_string", requests.first.first.search_string
        assert_equal true, requests.first.first.disable_spring?
      end

      def test_request__example_name
        requests = parse("path/to/file_test.rb --name example_name", {})

        assert_equal "path/to/file_test.rb", requests.first.first.search_string
        assert_equal "example_name", requests.first.first.example_name
      end

      def test_request__example_name__regex
        requests = parse("path/to/file_test.rb --name /example_name/", {})

        assert_equal "path/to/file_test.rb", requests.first.first.search_string
        assert_equal "/example_name/", requests.first.first.example_name
      end

      def test_request__example_name__with_equal_sign
        requests = parse("path/to/file_test.rb --name=/example_name/", {})

        assert_equal "path/to/file_test.rb", requests.first.first.search_string
        assert_equal "/example_name/", requests.first.first.example_name
      end

      def test_request__example_name__short_option
        requests = parse("path/to/file_test.rb -n /example_name/", {})

        assert_equal "path/to/file_test.rb", requests.first.first.search_string
        assert_equal "/example_name/", requests.first.first.example_name
      end

      def test_splits_on_spaces
        requests = parse("query with spaces", {})

        assert_equal "query", requests[0].first.search_string
        assert_equal "with", requests[1].first.search_string
        assert_equal "spaces", requests[2].first.search_string
      end

      private

      def parse(input, env)
        InputParser.new(input.split(" "), env).requests(shell: dummy_shell, searcher: nil)
      end
    end
  end
end

require "test_helper"
require "test_launcher/cli/input_parser"

module TestLauncher
  module CLI
    class InputParserTest < TestCase

      def test_request__defaults
        query = parse("a_string", {})

        assert_equal "a_string", query.requests.first.search_string
        assert_equal false, query.requests.first.run_all?
        assert_equal false, query.requests.first.disable_spring?
        assert_equal nil, query.requests.first.example_name
      end

      def test_request__all
        query = parse("a_string --all", {})

        assert_equal "a_string", query.requests.first.search_string
        assert_equal true, query.requests.first.run_all?
      end

      def test_request__disable_spring
        query = parse("a_string", {"DISABLE_SPRING" => "1"})

        assert_equal "a_string", query.requests.first.search_string
        assert_equal true, query.requests.first.disable_spring?
      end

      def test_request__example_name
        query = parse("path/to/file_test.rb --name example_name", {})

        assert_equal "path/to/file_test.rb", query.requests.first.search_string
        assert_equal "example_name", query.requests.first.example_name
      end

      def test_request__example_name__regex
        query = parse("path/to/file_test.rb --name /example_name/", {})

        assert_equal "path/to/file_test.rb", query.requests.first.search_string
        assert_equal "/example_name/", query.requests.first.example_name
      end

      def test_request__example_name__with_equal_sign
        query = parse("path/to/file_test.rb --name=/example_name/", {})

        assert_equal "path/to/file_test.rb", query.requests.first.search_string
        assert_equal "/example_name/", query.requests.first.example_name
      end

      def test_request__example_name__short_option
        query = parse("path/to/file_test.rb -n /example_name/", {})

        assert_equal "path/to/file_test.rb", query.requests.first.search_string
        assert_equal "/example_name/", query.requests.first.example_name
      end

      def test_joins_spaces
        query = parse("query with spaces", {})

        assert_equal "query with spaces", query.requests.first.search_string
      end

      private

      def parse(input, env)
        InputParser.new(input.split(" "), env).query(shell: dummy_shell, searcher: nil)
      end
    end
  end
end

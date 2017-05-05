require "test_helper"
require "test_launcher/cli/input_parser"

module TestLauncher
  module CLI
    class InputParserTest < TestCase

      def test_request__defaults
        requests = parse("a_string", {})

        assert_equal "a_string", requests.first.search_string
        assert_equal false, requests.first.run_all?
        assert_equal false, requests.first.disable_spring?
        assert_equal nil, requests.first.example_name
      end

      def test_request__all
        requests = parse("a_string --all", {})

        assert_equal "a_string", requests.first.search_string
        assert_equal true, requests.first.run_all?
      end

      def test_request__rerun
        requests = parse("--rerun", {})

        assert_equal true, requests.first.rerun?
      end


      def test_request__disable_spring
        requests = parse("a_string", {"DISABLE_SPRING" => "1"})

        assert_equal "a_string", requests.first.search_string
        assert_equal true, requests.first.disable_spring?
      end

      def test_request__example_name
        requests = parse("path/to/file_test.rb --name example_name", {})

        assert_equal "path/to/file_test.rb", requests.first.search_string
        assert_equal "example_name", requests.first.example_name
      end

      def test_request__example_name__regex
        requests = parse("path/to/file_test.rb --name /example_name/", {})

        assert_equal "path/to/file_test.rb", requests.first.search_string
        assert_equal "/example_name/", requests.first.example_name
      end

      def test_request__example_name__with_equal_sign
        requests = parse("path/to/file_test.rb --name=/example_name/", {})

        assert_equal "path/to/file_test.rb", requests.first.search_string
        assert_equal "/example_name/", requests.first.example_name
      end

      def test_request__example_name__short_option
        requests = parse("path/to/file_test.rb -n /example_name/", {})

        assert_equal "path/to/file_test.rb", requests.first.search_string
        assert_equal "/example_name/", requests.first.example_name
      end

      def test_joins_spaces
        requests = parse("query with spaces", {})

        assert_equal "query with spaces", requests.first.search_string
      end

      private

      def parse(input, env)
        InputParser.new(input.split(" "), env).requests(shell: dummy_shell, searcher: nil)
      end
    end
  end
end

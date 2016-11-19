require "test_helper"
require "test_launcher/cli/input_parser"

module TestLauncher
  module CLI
    class InputParserTest < TestCase

      def test_request__defaults
        request = parse("a_string", {})

        assert_equal "a_string", request.raw_options.query
        assert_equal false, request.raw_options.run_all?
        assert_equal false, request.raw_options.disable_spring?
        assert_equal nil, request.raw_options.example_name
      end

      def test_request__all
        request = parse("a_string --all", {})

        assert_equal "a_string", request.raw_options.query
        assert_equal true, request.raw_options.run_all?
      end

      def test_request__disable_spring
        request = parse("a_string", {"DISABLE_SPRING" => "1"})

        assert_equal "a_string", request.raw_options.query
        assert_equal true, request.raw_options.disable_spring?
      end

      def test_request__example_name
        request = parse("path/to/file_test.rb --name example_name", {})

        assert_equal "path/to/file_test.rb", request.raw_options.query
        assert_equal "example_name", request.raw_options.example_name
      end

      def test_request__example_name__regex
        request = parse("path/to/file_test.rb --name /example_name/", {})

        assert_equal "path/to/file_test.rb", request.raw_options.query
        assert_equal "/example_name/", request.raw_options.example_name
      end

      def test_request__example_name__with_equal_sign
        request = parse("path/to/file_test.rb --name=/example_name/", {})

        assert_equal "path/to/file_test.rb", request.raw_options.query
        assert_equal "/example_name/", request.raw_options.example_name
      end

      def test_request__example_name__short_option
        request = parse("path/to/file_test.rb -n /example_name/", {})

        assert_equal "path/to/file_test.rb", request.raw_options.query
        assert_equal "/example_name/", request.raw_options.example_name
      end

      def test_joins_spaces
        request = parse("query with spaces", {})

        assert_equal "query with spaces", request.raw_options.query
      end

      private

      def parse(input, env)
        InputParser.new(input.split(" "), env).request(shell: dummy_shell, searcher: nil)
      end
    end
  end
end

require "test_helper"
require "test_launcher/cli/input_parser"

module TestLauncher
  module CLI
    class InputParserTest < TestCase

      def test_request__defaults
        options = parse("a_string", {})

        assert_equal "a_string", options.search_string
        assert_equal false, options.run_all
        assert_equal false, options.disable_spring
        assert_equal nil, options.example_name
      end

      def test_request__all
        options = parse("a_string --all", {})

        assert_equal "a_string", options.search_string
        assert_equal true, options.run_all
      end

      def test_request__rerun
        options = parse("--rerun", {})

        assert_equal true, options.rerun
      end


      def test_request__disable_spring
        options = parse("a_string", {"DISABLE_SPRING" => "1"})

        assert_equal "a_string", options.search_string
        assert_equal true, options.disable_spring
      end

      def test_request__example_name
        options = parse("path/to/file_test.rb --name example_name", {})

        assert_equal "path/to/file_test.rb", options.search_string
        assert_equal "example_name", options.example_name
      end

      def test_request__example_name__regex
        options = parse("path/to/file_test.rb --name /example_name/", {})

        assert_equal "path/to/file_test.rb", options.search_string
        assert_equal "/example_name/", options.example_name
      end

      def test_request__example_name__with_equal_sign
        options = parse("path/to/file_test.rb --name=/example_name/", {})

        assert_equal "path/to/file_test.rb", options.search_string
        assert_equal "/example_name/", options.example_name
      end

      def test_request__example_name__short_option
        options = parse("path/to/file_test.rb -n /example_name/", {})

        assert_equal "path/to/file_test.rb", options.search_string
        assert_equal "/example_name/", options.example_name
      end

      def test_joins_spaces
        options = parse("query with spaces", {})

        assert_equal "query with spaces", options.search_string
      end

      private

      def parse(input, env)
        InputParser.new(input.split(" "), env).parsed_options(shell: dummy_shell, searcher: nil)
      end
    end
  end
end

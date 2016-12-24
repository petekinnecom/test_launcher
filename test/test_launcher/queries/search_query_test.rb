require "test_helper"
require "test_helpers/mocks"
require "test_launcher/queries"

module TestLauncher
  module Queries
    class SearchQueryTest < TestCase
      include DefaultMocks

      def test__multi_search_term__hits
        command_finder = Mock.new(Queries::CommandFinder, multi_search_term: :multi_search_term)
        request = MockRequest.new(search_string: "a b")

        assert_equal :multi_search_term, SearchQuery.new(request, command_finder).command
      end

      def test__multi_search_term__misses
        command_finder = Mock.new(Queries::CommandFinder, multi_search_term: nil, single_search_term: :single_search_term)
        request = MockRequest.new(search_string: "a b")

        assert_equal :single_search_term, SearchQuery.new(request, command_finder).command
      end

      def test__line_number__hits
        command_finder = Mock.new(Queries::CommandFinder, line_number: :line_number)
        request = MockRequest.new(search_string: "a:1")

        assert_equal :line_number, SearchQuery.new(request, command_finder).command
      end

      def test__line_number__misses
        command_finder = Mock.new(Queries::CommandFinder, line_number: nil, single_search_term: :single_search_term)
        request = MockRequest.new(search_string: "a:1")

        assert_equal :single_search_term, SearchQuery.new(request, command_finder).command
      end

      def test__single_search_term
        command_finder = Mock.new(Queries::CommandFinder, single_search_term: :single_search_term)
        request = MockRequest.new(search_string: "a")

        assert_equal :single_search_term, SearchQuery.new(request, command_finder).command
      end

      def test__none
        command_finder = Mock.new(Queries::CommandFinder, single_search_term: nil)
        request = MockRequest.new(search_string: "a")

        assert_equal nil, SearchQuery.new(request, command_finder).command
      end

    end
  end
end

require "test_helper"
require "test_helpers/mocks"
require "test_launcher/queries"

module TestLauncher
  module Queries
    class SingleTermQueryTest < TestCase
      include DefaultMocks

      def test__by_path
        command_finder = Mock.new(Queries::CommandFinder, by_path: :by_path)

        assert_equal :by_path, SingleTermQuery.new(MockRequest.new, command_finder).command
      end

      def test__example_name
        command_finder = Mock.new(Queries::CommandFinder, by_path: nil, example_name: :example_name)

        assert_equal :example_name, SingleTermQuery.new(MockRequest.new, command_finder).command
      end

      def test__from_full_regex
        command_finder = Mock.new(Queries::CommandFinder, by_path: nil, example_name: nil, from_full_regex: :from_full_regex)

        assert_equal :from_full_regex, SingleTermQuery.new(MockRequest.new, command_finder).command
      end

      def test__none
        command_finder = Mock.new(Queries::CommandFinder, by_path: nil, example_name: nil, from_full_regex: nil)

        assert_equal nil, SingleTermQuery.new(MockRequest.new, command_finder).command
      end

    end
  end
end

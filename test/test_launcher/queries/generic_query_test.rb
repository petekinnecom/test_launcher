require "test_helper"
require "test_helpers/mocks"
require "test_launcher/queries"

module TestLauncher
  module Queries
    class GenericQueryTest < TestCase
      include DefaultMocks

      def test__specified_name
        command_finder = Mock.new(Queries::CommandFinder, specified_name: :specified_name)

        assert_equal :specified_name, GenericQuery.new(MockRequest.new(example_name: "name_present", rerun?: false), command_finder).command
      end

      def test__example_name
        command_finder = Mock.new(Queries::CommandFinder, full_search: :full_search)

        assert_equal :full_search, GenericQuery.new(MockRequest.new(example_name: nil, rerun?: false), command_finder).command
      end
    end
  end
end

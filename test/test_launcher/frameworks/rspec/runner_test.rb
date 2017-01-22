require "test_helper"
require "test_helpers/mocks"
require "test_launcher/frameworks/rspec"

module TestLauncher
  module Frameworks
    module RSpec
      class RunnerTest < ::TestCase

        class MockTestCase < Mock
          mocks RSpec::TestCase
        end

        def test_single_example
          test_case = MockTestCase.new(
            example: "example_name",
            app_root: "app_root",
            file: "file"
          )
          assert_equal "cd app_root && bundle exec rspec file --example example_name", Runner.new.single_example(test_case)
        end

        def test_single_example__with_messy_name
          test_case = MockTestCase.new(
            example: "this is it's name :(",
            app_root: "app_root",
            file: "file"
          )
          assert_equal "cd app_root && bundle exec rspec file --example this\\ is\\ it\\'s\\ name\\ :\\(", Runner.new.single_example(test_case)
        end


        def test_multiple_examples_same_file
          test_cases = [
            MockTestCase.new(
              example: "example_name",
              app_root: "app_root",
              file: "file"
            ),
            MockTestCase.new(
              example: "example_name",
              app_root: "app_root",
              file: "file"
            )
          ]
          assert_equal "cd app_root && bundle exec rspec file --example example_name", Runner.new.multiple_examples_same_file(test_cases)
        end

        def test_single_file
          test_case = MockTestCase.new(
            example: "example_name",
            app_root: "app_root",
            file: "file"
          )
          assert_equal "cd app_root && bundle exec rspec file", Runner.new.single_file(test_case)
        end

        def test_one_or_more_files
          test_cases = [
            MockTestCase.new(
              example: "example_name",
              app_root: "app_root",
              file: "file_1"
            ),
            MockTestCase.new(
              example: "example_name",
              app_root: "app_root",
              file: "file_2"
            )
          ]
          assert_equal "cd app_root && bundle exec rspec file_1 file_2", Runner.new.one_or_more_files(test_cases)
        end
      end
    end
  end
end

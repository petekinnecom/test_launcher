require "test_helper"
require "test_helpers/mocks"
require "test_launcher/frameworks/minitest"

module TestLauncher
  module Frameworks
    module Minitest
      class RunnerTest < ::TestCase

        class MockTestCase < Mock
          mocks Minitest::TestCase
        end

        def test_single_example
          test_case = MockTestCase.new(
            example: "example_name",
            app_root: "app_root",
            example_runner: "example_runner",
            file: "file",
            spring_enabled?: false
          )
          assert_equal "cd app_root && example_runner file --name='/example_name/'", Runner.new.single_example(test_case)
        end

        def test_multiple_examples_same_file
          test_cases = [
            MockTestCase.new(
              example: "example_name",
              app_root: "app_root",
              example_runner: "example_runner",
              file: "file",
              spring_enabled?: false
            ),
            MockTestCase.new(
              example: "example_name",
              app_root: "app_root",
              example_runner: "example_runner",
              file: "file"
            )
          ]
          assert_equal "cd app_root && example_runner file --name='/example_name/'", Runner.new.multiple_examples_same_file(test_cases)
        end

        def test_single_file
          test_case = MockTestCase.new(
            example: "example_name",
            app_root: "app_root",
            file_runner: "file_runner",
            file: "file"
          )
          assert_equal "cd app_root && file_runner file", Runner.new.single_file(test_case)
        end

        def test_one_or_more_files
          test_cases = [
            MockTestCase.new(
              example: "example_name",
              app_root: "app_root",
              file_runner: "file_runner",
              file: "file_1"
            ),
            MockTestCase.new(
              example: "example_name",
              app_root: "app_root",
              file_runner: "file_runner",
              file: "file_2"
            )
          ]
          assert_equal "cd app_root && file_runner file_1 file_2", Runner.new.one_or_more_files(test_cases)
        end
      end
    end
  end
end

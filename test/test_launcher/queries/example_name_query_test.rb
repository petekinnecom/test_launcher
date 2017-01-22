require "test_helper"
require "test_helpers/mocks"
require "test_launcher/queries"
require "test_launcher/frameworks/minitest"

module TestLauncher
  module Queries
    class ExampleNameQueryTest < TestCase
      include DefaultMocks

      def raw_searcher
        @raw_searcher ||= MemorySearcher.new do |searcher|
          searcher.mock_file do |f|
            f.path "file_1_test.rb"
            f.mtime Time.now - 3000
            f.contents <<-RB
              class SingleTest
                def test__one_example
                  matches_single
                end

                def test__same_file_1
                end

                def test__same_file_2
                end

                def test__different_files
                end
              end
            RB
          end

          searcher.mock_file do |f|
            f.path "file_2_test.rb"
            f.mtime Time.now
            f.contents <<-RB
              class MultipleMatches1Test
                def test__different_files
                end
              end
            RB
          end

          searcher.mock_file do |f|
            f.path "multiple_matches_2_test.rb"
            f.mtime Time.now
            f.contents <<-RB
              class MultipleMatches2Test
                def test__1
                  multiple_matches_2
                end

                def test__2
                  multiple_matches_2
                end
              end
            RB
          end
        end
      end

      def searcher
        @searcher ||= Frameworks::Minitest::Searcher.new(raw_searcher)
      end

      def runner
        @runner ||= MockRunner.new do |m|

          m.impl :single_example do |test_case|
            "single_example #{test_case.file} #{test_case.example}"
          end

          m.impl :multiple_examples_same_file do |test_cases|
            "multiple_examples_same_file #{test_cases.first.file} #{test_cases.first.example}"
          end

          m.impl :multiple_files do |test_cases|
            "multiple_files #{test_cases.map(&:file).join(" ")}"
          end

          m.impl :multiple_examples do |test_cases|
            "multiple_examples #{test_cases.map(&:file).join(" ")}"
          end
        end
      end

      def test_command__example_not_found__returns_nil
        request = MockRequest.new(
          search_string: "not_found",
          searcher: searcher
        )

        command = ExampleNameQuery.new(request, default_command_finder).command

        assert_equal nil, command
      end

      def test_command__one_example_found
        request = MockRequest.new(
          search_string: "one_example",
          searcher: searcher,
          runner: runner,
          shell: default_shell
        )

        command = ExampleNameQuery.new(request, default_command_finder).command

        assert_equal "single_example file_1_test.rb one_example", command
      end

      def test_command__one_example_found__notifies
        request = MockRequest.new(
          search_string: "one_example",
          searcher: searcher,
          runner: runner,
          shell: default_shell
        )

        command = ExampleNameQuery.new(request, default_command_finder).command

        messages = [
          ["Found 1 example in 1 file."],
        ]
        assert_equal messages, default_shell.recall(:notify)
      end

      def test_command__multiple_examples__one_file
        request = MockRequest.new(
          search_string: "same_file",
          searcher: searcher,
          runner: runner,
          shell: default_shell
        )

        command = ExampleNameQuery.new(request, default_command_finder).command

        assert_equal "multiple_examples_same_file file_1_test.rb same_file", command
      end

      def test_command__multiple_examples__one_file__notifies
        request = MockRequest.new(
          search_string: "same_file",
          searcher: searcher,
          runner: runner,
          shell: default_shell
        )

        command = ExampleNameQuery.new(request, default_command_finder).command

        messages = [
          ["Found 2 examples in 1 file."],
        ]
        assert_equal messages, default_shell.recall(:notify)
      end

      def test_command__multiple_examples__multiple_files__no_all
        request = MockRequest.new(
          search_string: "different_files",
          searcher: searcher,
          runner: runner,
          shell: default_shell,
          run_all?: false
        )

        command = ExampleNameQuery.new(request, default_command_finder).command

        assert_equal "single_example file_2_test.rb different_files", command
      end

      def test_command__multiple_examples__multiple_files__no_all__notifies
        request = MockRequest.new(
          search_string: "different_files",
          searcher: searcher,
          runner: runner,
          shell: default_shell,
          run_all?: false
        )

        command = ExampleNameQuery.new(request, default_command_finder).command

        messages = [
          ["Found 2 examples in 2 files."],
          ["Running most recently edited. Run with '--all' to run all the tests."],
        ]
        assert_equal messages, default_shell.recall(:notify)
      end

      def test_command__multiple_examples__multiple_files__all
        request = MockRequest.new(
          search_string: "different_files",
          searcher: searcher,
          runner: runner,
          shell: default_shell,
          run_all?: true
        )

        command = ExampleNameQuery.new(request, default_command_finder).command

        assert_equal "multiple_examples file_1_test.rb file_2_test.rb", command
      end

      def test_command__multiple_examples__multiple_files__all__notifies
        request = MockRequest.new(
          search_string: "different_files",
          searcher: searcher,
          runner: runner,
          shell: default_shell,
          run_all?: true
        )

        command = ExampleNameQuery.new(request, default_command_finder).command

        messages = [
          ["Found 2 examples in 2 files."],
        ]
        assert_equal messages, default_shell.recall(:notify)
      end
    end
  end
end

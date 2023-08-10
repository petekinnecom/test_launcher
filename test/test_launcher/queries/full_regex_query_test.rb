require "test_helper"
require "test_helpers/mocks"
require "test_launcher/queries"
require "test_launcher/frameworks/minitest"

module TestLauncher
  module Queries
    class FullRegexQueryTest < TestCase
      include DefaultMocks

      def raw_searcher
        @raw_searcher ||= MemorySearcher.new do |searcher|
          searcher.mock_file do |f|
            f.path "single_test.rb"
            f.contents <<-RB
              class SingleTest
                def test__1
                  matches_single
                end
              end
            RB
          end

          searcher.mock_file do |f|
            f.path "multiple_matches_1_test.rb"
            f.mtime Time.now - 3000
            f.contents <<-RB
              class MultipleMatches1Test
                def test__1
                  multiple_matches_1
                end

                def test__2
                  multiple_matches_1
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
          m.impl :single_file do |test_case|
            case test_case.file.sub(%r{#{raw_searcher.dir}/}, "")
            when "single_test.rb"
              "single_file single_test.rb"
            when "multiple_matches_1_test.rb"
              "single_file multiple_matches_1_test.rb"
            when "multiple_matches_2_test.rb"
              "single_file multiple_matches_2_test.rb"
            else
              raise "unmocked single_file: #{test_case.file}"
            end
          end

          m.impl :multiple_files do |test_cases|
            case test_cases.map {|tc| tc.file.sub(%r{#{raw_searcher.dir}/}, "") }
            when ["multiple_matches_1_test.rb", "multiple_matches_2_test.rb"]
              "multiple_files multiple_matches_1_test.rb multiple_matches_2_test.rb"
            else
              raise "unmocked multiple_files: #{test_cases}"
            end
          end
        end
      end

      def test_command__regex_not_found
        request = MockRequest.new(
          search_string: "not_found",
          searcher: searcher
        )

        command = FullRegexQuery.new(request, default_command_finder).command
        assert_equal nil, command
      end

      def test_command__single_match
        request = MockRequest.new(
          search_string: "single",
          searcher: searcher,
          runner: runner,
          shell: default_shell
        )

        command = FullRegexQuery.new(request, default_command_finder).command

        assert_equal "single_file single_test.rb", command
      end

      def test_command__multiple_matches_same_file
        request = MockRequest.new(
          search_string: "multiple_matches_1",
          searcher: searcher,
          runner: runner,
          shell: default_shell
        )

        command = FullRegexQuery.new(request, default_command_finder).command

        assert_equal "single_file multiple_matches_1_test.rb", command
      end

      def test_command__multiple_matches_different_files__no_all
        request = MockRequest.new(
          search_string: "multiple_matches",
          searcher: searcher,
          runner: runner,
          shell: default_shell,
          run_all?: false
        )

        command = FullRegexQuery.new(request, default_command_finder).command

        assert_equal "single_file multiple_matches_2_test.rb", command
      end

      def test_command__multiple_matches_different_files__all
        request = MockRequest.new(
          search_string: "multiple_matches",
          searcher: searcher,
          runner: runner,
          shell: default_shell,
          run_all?: true
        )

        command = FullRegexQuery.new(request, default_command_finder).command

        assert_equal "multiple_files multiple_matches_1_test.rb multiple_matches_2_test.rb", command
      end
    end
  end
end

require "test_helper"
require "test_helpers/mocks"
require "test_launcher/search/git"
require "test_launcher/frameworks/minitest"

module TestLauncher
  module Frameworks
    module Minitest
      class SearcherTest < ::TestCase
        include DefaultMocks

        class RawSearcherMock < Mock
          mocks Search::Git

          impl :grep do |regex, file_pattern:|
            example_name_regex = "^\s*(def\s+test_|test\s+['\"]).*().*" #TODO: no bueno copying this
            case [regex, file_pattern]
            when [example_name_regex, "test/test_launcher/single_test.rb"]
              [
                {file: "test/test_launcher/single_test.rb", line_number: 8, line: "def test__first"},
                {file: "test/test_launcher/single_test.rb", line_number: 13, line: "def test__second"},
                {file: "test/test_launcher/single_test.rb", line_number: 18, line: "def test__third"},
              ]
            when [example_name_regex, "root_path/non_test_file"]
              []
            when [example_name_regex, "root_path/multiple_1"]
              [
                "test/dir/1_multiple_test.rb:8:     def test__first",
                "test/dir/1_multiple_test.rb:13:    def test__second",
              ]
            when [example_name_regex, "root_path/multiple_2"]
              [
                "test/dir/2_multiple_test.rb:12:    def test__first",
                "test/dir/2_multiple_test.rb:30:    def test__second",
              ]
            else
              raise "unmocked search: #{regex}, #{file_pattern}"
            end
          end

          impl :find_files do |pattern|
            case pattern
            when "not_found_test.rb"
              []
            when "single_test.rb"
              ["test/test_launcher/single_test.rb"]
            when "non_test_file.rb"
              ["non_test_file.rb"]
            when "multiple_test.rb"
              ["test/dir/1_multiple_test.rb", "test/dir/2_multiple_test.rb"]
            else
              raise "unmocked search: #{pattern}"
            end
          end
        end

        def searcher
          @searcher ||= Searcher.new(RawSearcherMock.new)
        end

        def test_by_line__file_not_found
          assert_equal [], searcher.by_line("not_found_test.rb", 1)
        end

        def test_by_line__file_is_not_test_file
          assert_equal [], searcher.by_line("non_test_file.rb", 1)
        end

        def test_by_line__single_file_line_before_all_examples
          expected_result = [{file: "test/test_launcher/single_test.rb"}]
          assert_equal expected_result, searcher.by_line("single_test.rb", 1)
        end

        def test_by_line__single_file_line_exact_number
          expected_result = [{
            file: "test/test_launcher/single_test.rb",
            example_name: "test__first",
            line_number: 8
          }]
          assert_equal expected_result, searcher.by_line("single_test.rb", 8)
        end

        def test_by_line__single_file_line_after_example
          expected_result = [{
            file: "test/test_launcher/single_test.rb",
            example_name: "test__first",
            line_number: 8
          }]
          assert_equal expected_result, searcher.by_line("single_test.rb", 10)
        end

        def test_by_line__single_file_line_after_example_2
          expected_result = [{
            file: "test/test_launcher/single_test.rb",
            example_name: "test__second",
            line_number: 13
          }]
          assert_equal expected_result, searcher.by_line("single_test.rb", 17)
        end

        def test_by_line__multiple_files__raises_error_for_now
          assert_raises Searcher::MultipleByLineMatches do
            searcher.by_line("multiple_test.rb", 1)
          end
        end
      end
    end
  end
end

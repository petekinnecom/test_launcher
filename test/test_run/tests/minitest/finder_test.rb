require "test_helper"
require "test_run/tests/minitest/finder"

module TestLauncher
  module Tests
    module Minitest
      class FinderTest < TestCase

        def test_find__absolute_path
          Dir.expects(:pwd).returns("/absolute/path/root")
          results = Finder.find("/absolute/path/root/test/dir/file_test.rb", "searcher_stub")
          assert_equal [{file: "test/dir/file_test.rb"}], results
        end

        def test_find__found_by_name
          expected = [{file: "test/file.rb", line: "def test_name"}]
          searcher_mock = mock do
            stubs(:grep).with("^\s*def .*test_name.*", file_pattern: "*_test.rb").returns(expected)
          end

          assert_equal expected, Finder.find("test_name", searcher_mock)
        end

        def test_find__found_by_file_name
          searcher_mock = mock do
            stubs(:grep).returns([])
            stubs(:find_files).with("file_query").returns([
               "dir/test/non_test_file_query.rb",
               "dir/thing/file_query_test.rb",
               "other_dir/other_thing/other_file_query_test.rb",
            ])
          end

          expected = [
              { file: "dir/thing/file_query_test.rb" },
              { file: "other_dir/other_thing/other_file_query_test.rb" },
            ]

          assert_equal expected, Finder.find("file_query", searcher_mock)
        end

        def test_find__found_by_full_regex
          searcher_mock = mock do
            stubs(:grep).returns([])
            stubs(:find_files).returns([])

            stubs(:grep).with("full_regex_search", file_pattern: "*_test.rb").returns([
              { file: "path/to/file_test.rb", line: "random_match"},
              { file: "path/to/other_file_test.rb", line: "random_match_2"}
            ])
          end

          expected = [
              {file: "path/to/file_test.rb"},
              {file: "path/to/other_file_test.rb"}
            ]
          assert_equal expected, Finder.find("full_regex_search", searcher_mock)
        end

        def test_find__nothing_found
          searcher_mock = mock do
            stubs(:grep).returns([])
            stubs(:find_files).returns([])
          end

          assert_equal [], Finder.find("query", searcher_mock)
        end
      end
    end
  end
end

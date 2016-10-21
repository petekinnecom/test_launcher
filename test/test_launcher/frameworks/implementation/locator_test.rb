require 'test_helper'

module TestLauncher
  module Frameworks
    module Implementation
      class LocatorTest < ::TestCase
        class DummyTestCase < Implementation::TestCase
        end

        class DummyLocator < Implementation::Locator
          def file_name_regex
            /_test.rb/
          end

          def file_name_pattern
            "*"
          end

          def regex_pattern
            /.*/
          end

          def test_case_class
            DummyTestCase
          end
        end

        def test_prioritized_results__files_found_by_path__does_not_run_if_not_matching_regex__one_arg
          searcher = mock {
            stubs(:grep).returns([{file: "dummy_result"}])
            expects(:find_files).never
          }

          request = stub(query: "file_not_matching_regex.js", run_all: false)

          locator = DummyLocator.new(request, searcher)

          assert_equal 1, locator.prioritized_results.file_count

          result = locator.prioritized_results.first
          assert_equal "dummy_result", result.file
        end

        def test_prioritized_results__files_found_by_path__does_not_run_if_not_matching_regex__all_args
          searcher = mock {
            stubs(:grep).returns([{file: "dummy_result"}])
            expects(:find_files).never
          }

          request = stub(query: "matching_test.rb non_matching.js", run_all: false)

          locator = DummyLocator.new(request, searcher)

          assert_equal 1, locator.prioritized_results.file_count

          result = locator.prioritized_results.first
          assert_equal "dummy_result", result.file
        end

        def test_prioritized_results__files_found_by_path__uses_searcher_if_all_files_match_regex
          searcher = mock {
            expects(:find_files).with("matching_test.rb").returns(["/path/to/matching_test.rb"])
          }

          request = stub(query: "matching_test.rb ", run_all: false)

          locator = DummyLocator.new(request, searcher)

          assert_equal 1, locator.prioritized_results.file_count

          result = locator.prioritized_results.first
          assert_equal "/path/to/matching_test.rb", result.file
        end

        def test_prioritized_results__files_found_by_path__uses_searcher_if_all_files_match_regex__multiple_results
          searcher = mock {
            expects(:find_files).with("matching_test.rb").returns(["/path1/to/matching_test.rb", "/path2/to/matching_test.rb"])
          }

          request = stub(query: "matching_test.rb ", run_all: false)

          locator = DummyLocator.new(request, searcher)

          assert_equal 2, locator.prioritized_results.file_count

          assert_equal "/path1/to/matching_test.rb", locator.prioritized_results.first.file
          assert_equal "/path2/to/matching_test.rb", locator.prioritized_results.last.file
        end

        def test_prioritized_results__files_found_by_path__uses_searcher_if_all_files_match_regex__multiple_args
          searcher = mock {
            expects(:find_files).with("matching_1_test.rb").returns(["/path1/to/matching_1_test.rb", "/path2/to/matching_1_test.rb"])
            expects(:find_files).with("matching_2_test.rb").returns(["/path1/to/matching_2_test.rb", "/path2/to/matching_2_test.rb"])
          }

          request = stub(query: "matching_1_test.rb matching_2_test.rb", run_all: false)

          locator = DummyLocator.new(request, searcher)

          assert_equal 4, locator.prioritized_results.file_count

          file_results = locator.prioritized_results.map(&:file)

          assert file_results.include?("/path1/to/matching_1_test.rb")
          assert file_results.include?("/path2/to/matching_1_test.rb")
          assert file_results.include?("/path1/to/matching_2_test.rb")
          assert file_results.include?("/path2/to/matching_2_test.rb")
        end

        def test_prioritized_results__files_found_by_path__raises_unsupported_search_error
          # if we find results for one path, but not for the other
          # then we are confused as to what to do.

          searcher = mock {
            expects(:find_files).with("matching_1_test.rb").returns(["/path1/to/matching_1_test.rb", "/path2/to/matching_1_test.rb"])
            expects(:find_files).with("matching_2_test.rb").returns([])
          }
          request = stub(query: "matching_1_test.rb matching_2_test.rb", run_all: false)

          locator = DummyLocator.new(request, searcher)

          assert_raises Implementation::UnsupportedSearchError do
            locator.prioritized_results
          end
        end

        def test_prioritized_results__files_found_by_path__runs_all_if_multiple_searches
          searcher = mock {
            expects(:find_files).with("matching_1_test.rb").returns(["/path1/to/matching_1_test.rb", "/path2/to/matching_1_test.rb"])
            expects(:find_files).with("matching_2_test.rb").returns(["/path1/to/matching_2_test.rb", "/path2/to/matching_2_test.rb"])
          }
          request = stub(query: "matching_1_test.rb matching_2_test.rb", run_all: false)

          locator = DummyLocator.new(request, searcher)

          assert locator.prioritized_results.run_all?
        end

        def test_prioritized_results__files_found_by_path__does_not_run_all_if_single_search
          searcher = mock {
            expects(:find_files).with("matching_test.rb").returns(["/path1/to/matching_1_test.rb", "/path2/to/matching_1_test.rb"])
          }
          request = stub(query: "matching_test.rb", run_all: false)

          locator = DummyLocator.new(request, searcher)

          assert ! locator.prioritized_results.run_all?
        end

        def test_prioritized_results__files_found_by_path__does_not_run_all_if_single_search_unless_override
          searcher = mock {
            expects(:find_files).with("matching_test.rb").returns(["/path1/to/matching_1_test.rb", "/path2/to/matching_1_test.rb"])
          }

          request = stub(query: "matching_test.rb", run_all: true)

          locator = DummyLocator.new(request, searcher)

          assert locator.prioritized_results.run_all?
        end
      end
    end
  end
end

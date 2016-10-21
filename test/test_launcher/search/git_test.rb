require "test_helper"
require "test_launcher/search/git"

module TestLauncher
  module Search
    class GitTest < TestCase

      def setup
        super
        Dir.stubs(:chdir)
      end

      def test_find_files__strips_absolute_path_for_search_and_replaces_it
        interface = mock {
          expects(:root_path).returns("/path/to/repo")
          expects(:ls_files).with("relative/file_test.rb").returns(["inline_gem/relative/file_test.rb"])
        }

        searcher = Git.new(nil, interface)
        files = searcher.find_files("/path/to/repo/relative/file_test.rb")

        assert_equal ["/path/to/repo/inline_gem/relative/file_test.rb"], files
      end
    end
  end
end

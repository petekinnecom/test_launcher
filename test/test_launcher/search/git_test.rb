require "test_helper"
require "test_launcher/search/git"
require "test_helpers/mocks"

module TestLauncher
  module Search
    class GitTest < TestCase
      include DefaultMocks

      def setup
        super
        Dir.stubs(:chdir)
      end

      def test_find_files__strips_absolute_path_for_search_and_replaces_it
        interface = mock.tap do |m|
          m.expects(:root_path).returns("/path/to/repo")
          m.expects(:ls_files).with("relative/file_test.rb").returns(["inline_gem/relative/file_test.rb"])
        end

        searcher = Git.new(nil, interface)
        files = searcher.find_files("/path/to/repo/relative/file_test.rb")

        assert_equal ["/path/to/repo/inline_gem/relative/file_test.rb"], files
      end

      def test_find_files__returns_file_if_exists
        # git ls-files will not find newly created files
        interface = mock.tap do |m|
          m.expects(:root_path).returns("/path/to/repo")
        end

        File.stubs(:exist?).with('thing_test.rb').returns(true)
        searcher = Git.new(nil, interface)
        files = searcher.find_files("thing_test.rb")

        assert_equal ['/path/to/repo/thing_test.rb'], files
      end
    end
  end
end

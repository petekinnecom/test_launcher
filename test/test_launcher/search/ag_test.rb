require "test_helper"
require "test_launcher/search/ag"
require "test_helpers/mocks"

module TestLauncher
  module Search
    class AgTest < TestCase
      include DefaultMocks

      def setup
        super
        Dir.stubs(:chdir)
      end

      def test_find_files__strips_absolute_path_for_search
        interface = mock {
          expects(:root_path).returns("/path/to/repo")
          expects(:ls_files).with("relative/file_test.rb").returns(["inline_gem/relative/file_test.rb"])
        }

        searcher = Ag.new(nil, interface)
        files = searcher.find_files("/path/to/repo/relative/file_test.rb")

        assert_equal ["/path/to/repo/inline_gem/relative/file_test.rb"], files
      end

      def test_grep__strips_absolute_path_of_file_pattern
        interface = mock {
          expects(:root_path).returns("/path/to/repo")
          expects(:grep).with("regex", "relative/file_test.rb").returns([
            "relative/file_test.rb:20:    def test_regex"
          ])
        }

        searcher = Ag.new(nil, interface)
        files = searcher.grep("regex", file_pattern: "/path/to/repo/relative/file_test.rb")

        assert_equal [{file: "/path/to/repo/relative/file_test.rb", line_number: 20, line: "def test_regex"}], files
      end
    end
  end
end

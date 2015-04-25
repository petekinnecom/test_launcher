require "test_helper"
require "test_run/searchers/git_searcher"

module TestRun
  module Searchers
    class MockShell
      def run(cmd)
        if cmd == "git ls-files '*file_pattern*'"
          [
            "file/path/one.rb",
            "another_file/path/two.rb",
          ]
        elsif cmd == "git grep --untracked 'regex' -- 'file_pattern'"
          [
            "file/path/one.rb: some_lines(of_code)",
            "another_file/path/two.rb:   Class::Thing::Stuff.new",
          ]
        else
          raise ArgumentError.new("unmocked command")
        end
      end
    end

    class GitSearcherTest < TestCase

      def test_find_files
        searcher = GitSearcher.new(MockShell.new)

        assert_equal ["file/path/one.rb", "another_file/path/two.rb"], searcher.find_files("file_pattern")
      end

      def test_grep
        searcher = GitSearcher.new(MockShell.new)

        expected = [
          {
            file: "file/path/one.rb",
            line: "some_lines(of_code)",
          },
          {
            file: "another_file/path/two.rb",
            line: "Class::Thing::Stuff.new",
          }
        ]

        assert_equal expected, searcher.grep("regex", file_pattern: "file_pattern")
      end
    end
  end
end

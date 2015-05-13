require "test_launcher/searchers/git_searcher"

module TestLauncher
  module Tests
    module Minitest
      class Finder < Struct.new(:query, :searcher)

        def self.find(query, searcher)
          new(query, searcher).find
        end

        def find
          return tests_found_by_absolute_path if query.match(/^\//)

          return tests_found_by_name unless tests_found_by_name.empty?

          return tests_found_by_file_name unless tests_found_by_file_name.empty?

          return tests_found_by_full_regex unless tests_found_by_full_regex.empty?

          []
        end

        private

        def tests_found_by_absolute_path
          relative_file_path = query.sub(Dir.pwd, '').sub(/^\//, '')
          [ {file: relative_file_path} ]
        end

        def tests_found_by_name
          @tests_found_by_name ||= full_regex_search("^\s*def .*#{query}.*")
        end

        def tests_found_by_file_name
          @tests_found_by_file_name ||= searcher.find_files(query).select { |f| f.match(/_test\.rb/) }.map {|f| {file: f} }
        end

        def tests_found_by_full_regex
          # we ignore the matched line since we don't know what to do with it
          @tests_found_by_full_regex ||= full_regex_search(query).map {|t| {file: t[:file]} }
        end

        def full_regex_search(regex)
          searcher.grep(regex, file_pattern: '*_test.rb')
        end
      end
    end
  end
end

require "test_launcher/searchers/git_searcher"

module TestLauncher
  module Frameworks
    module Minitest
      class ExampleFinder < Struct.new(:query, :searcher)

        def self.find(query, searcher)
          new(query, searcher).find
        end

        def find
          return files_found_by_absolute_path if query.match(/^\//)

          return examples_found_by_name unless examples_found_by_name.empty?

          return files_found_by_file_name unless files_found_by_file_name.empty?

          return files_found_by_full_regex unless files_found_by_full_regex.empty?

          []
        end

        private

        def files_found_by_absolute_path
          relative_file_path = query.sub(Dir.pwd, '').sub(/^\//, '')
          [ {file: relative_file_path} ]
        end

        def examples_found_by_name
          @examples_found_by_name ||= full_regex_search("^\s*def .*#{query}.*")
        end

        def files_found_by_file_name
          @files_found_by_file_name ||= searcher.find_files(query).select { |f| f.match(/_test\.rb/) }.map {|f| {file: f} }
        end

        def files_found_by_full_regex
          # we ignore the matched line since we don't know what to do with it
          @files_found_by_full_regex ||= full_regex_search(query).map {|t| {file: t[:file]} }
        end

        def full_regex_search(regex)
          searcher.grep(regex, file_pattern: '*_test.rb')
        end
      end
    end
  end
end

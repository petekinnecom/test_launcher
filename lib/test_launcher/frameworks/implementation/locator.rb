require "test_launcher/frameworks/implementation/test_case"
require "test_launcher/frameworks/implementation/collection"

module TestLauncher
  module Frameworks
    module Implementation
      class Locator < Struct.new(:query, :searcher)
        private :query, :searcher

        def prioritized_results
          Collection.new(_prioritized_results)
        end

        def _prioritized_results
          return files_found_by_absolute_path unless files_found_by_absolute_path.empty?

          return examples_found_by_name unless examples_found_by_name.empty?

          return files_found_by_file_name unless files_found_by_file_name.empty?

          return files_found_by_full_regex unless files_found_by_full_regex.empty?

          []
        end

        private

        def files_found_by_absolute_path
          return [] unless File.exist?(query)

          [ build_result(file: query) ]
        end

        def examples_found_by_name
          @examples_found_by_name ||= full_regex_search(regex_pattern).map {|r| build_result(file: r[:file], query: query)}
        end

        def files_found_by_file_name
          @files_found_by_file_name ||= searcher.find_files(query).select { |f| f.match(file_name_regex) }.map {|f| build_result(file: f) }
        end

        def files_found_by_full_regex
          # we ignore the matched line since we don't know what to do with it
          @files_found_by_full_regex ||= full_regex_search(query).map {|r| build_result(file: r[:file]) }
        end

        def full_regex_search(regex)
          searcher.grep(regex, file_pattern: file_name_pattern)
        end

        def build_result(file:, query: nil)
          test_case_class.from_search(file: file, query: query)
        end

        def file_name_regex
          raise NotImplementedError
        end

        def file_name_pattern
          raise NotImplementedError
        end

        def regex_pattern
          raise NotImplementedError
        end

        def test_case_class
          raise NotImplementedError
        end
      end
    end
  end
end

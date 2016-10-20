require "test_launcher/frameworks/implementation/test_case"
require "test_launcher/frameworks/implementation/collection"

module TestLauncher
  module Frameworks
    module Implementation
      class Locator < Struct.new(:request, :searcher)
        private :request, :searcher

        def prioritized_results
          return files_found_by_absolute_path unless files_found_by_absolute_path.empty?

          return examples_found_by_name unless examples_found_by_name.empty?

          return files_found_by_file_name unless files_found_by_file_name.empty?

          return files_found_by_full_regex unless files_found_by_full_regex.empty?

          []
        end

        private

        def files_found_by_absolute_path
          # TODO:
          # failure case: test_launcher a/b/c_test.rb a/b/d_test.rb => both files exist, but not absolute path.
          # this method should just be merged with the other one?

          potential_file_paths = request.query.split(" ")
          return [] unless potential_file_paths.all? {|fp| File.exist?(fp) && fp.match(/^\//)}

          Collection.new(
            results:  potential_file_paths.map {|fp| build_result(file: fp)},
            run_all: true
          )
        end

        def examples_found_by_name
          @examples_found_by_name ||= Collection.new(
            results: full_regex_search(regex_pattern).map {|r| build_result(file: r[:file], query: request.query)},
            run_all: request.run_all
          )
        end

        def files_found_by_file_name
          @files_found_by_file_name ||= begin
            potential_file_paths = request.query.split(" ")
            split_query_results = potential_file_paths.map {|fp| searcher.find_files(fp).select {|f| f.match(file_name_regex) } }

            return [] if split_query_results.any?(&:empty?)

            Collection.new(
              results: split_query_results.flatten.map {|f| build_result(file: f) },
              run_all: true,
            )
          end
        end

        def files_found_by_full_regex
          # we ignore the matched line since we don't know what to do with it
          @files_found_by_full_regex ||= Collection.new(
            results: full_regex_search(request.query).map {|r| build_result(file: r[:file]) },
            run_all: request.run_all
          )
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

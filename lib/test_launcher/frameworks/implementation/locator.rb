require "test_launcher/base_error"
require "test_launcher/frameworks/implementation/test_case"
require "test_launcher/frameworks/implementation/collection"

module TestLauncher
  module Frameworks
    module Implementation
      UnsupportedSearchError = Class.new(BaseError)
      UnfoundFileError = Class.new(BaseError)

      class Locator < Struct.new(:request, :searcher)
        private :request, :searcher

        def prioritized_results
          return files_found_by_path unless files_found_by_path.empty?

          return examples_found_by_name unless examples_found_by_name.empty?

          return files_found_by_file_name_regex unless files_found_by_file_name_regex.empty?

          return files_found_by_full_regex unless files_found_by_full_regex.empty?

          []
        end

        private

        def files_found_by_path
          # TODO: this needs some love

          @files_found_by_path ||= begin
            potential_file_paths = request.query.split(" ")
            if potential_file_paths.all? {|fp| fp.match(file_name_regex)}

              found_files = potential_file_paths.map {|fp| searcher.test_files(fp) }
              if found_files.any?(&:empty?)
                raise file_term_error
              end

              # TODO: we put in the example_name here in case it's a pass through call... bad bad bad
              Collection.new(
                results: found_files.flatten.map {|fp| build_result(file: fp, query: request.example_name)},
                run_all: request.run_all? || potential_file_paths.size > 1
              )
            else
              []
            end
          end
        end

        def examples_found_by_name
          @examples_found_by_name ||= Collection.new(
            results: full_regex_search(regex_pattern).map {|r| build_result(file: r[:file], query: request.query)},
            run_all: request.run_all?
          )
        end

        def files_found_by_file_name_regex
          @files_found_by_file_name_regex ||= begin
            potential_file_paths = request.query.split(" ")
            split_query_results = potential_file_paths.map {|fp| searcher.test_files(fp) }

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
            run_all: request.run_all?
          )
        end

        def full_regex_search(regex)
          searcher.grep(regex)
        end

        def build_result(file:, query: nil)
          test_case_class.from_search(file: file, query: query, request: request)
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

        def file_term_error
          if request.example_name
             UnfoundFileError.new("The specified test file could not be found.")
          else
            UnsupportedSearchError.new <<-MSG
At least one of your search terms was identified as a file.

At least one of your *other* search terms was identified to not be a file.

This is a case that is not currently supported.

It is possible that one of the test files you wish to run is not currently known to git (e.g. it is ignored or unstaged)

If that's not the case, let me know what you're trying to do by filing an issue at http://github.com/petekinnecom/test_launcher/issues
            MSG
          end
        end
      end
    end
  end
end

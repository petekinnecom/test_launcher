require "test_launcher/search/test_case"
require "test_launcher/search/collection"

module TestLauncher
  module Search

    # This class is abstract and is the parent to Base::SearchResults
    # Usages of this class should be through Base::SearchResults
    #
    # I don't like this, but I like how Base::SearchResults highlights what is
    # needed for new frameworks

    class Base < Struct.new(:query, :searcher)
      private :query, :searcher

      def prioritized_results
        Search::Collection.new(_prioritized_results)
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
        return [] unless query.match(/^\//)

        relative_file_path = query.sub(Dir.pwd, '').sub(/^\//, '')
        [ build_result(file: relative_file_path) ]
      end

      def examples_found_by_name
        @examples_found_by_name ||= full_regex_search(regex_pattern)
      end

      def files_found_by_file_name
        @files_found_by_file_name ||= searcher.find_files(query).select { |f| f.match(file_name_regex) }.map {|f| build_result(file: f) }
      end

      def files_found_by_full_regex
        # we ignore the matched line since we don't know what to do with it
        @files_found_by_full_regex ||= full_regex_search(query).map {|t| build_result(file: t.file) }
      end

      def full_regex_search(regex)
        searcher.grep(regex, file_pattern: file_name_pattern).map {|r| build_result(file: r[:file], line: r[:line])}
      end

      def build_result(file:, line: nil)
        test_case_class.from_search(file: file, line: line)
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

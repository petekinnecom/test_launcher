module TestLauncher
  class SearchResultsBase < Struct.new(:query, :searcher)
    class Result
      attr_reader :file, :line

      def initialize(file:, line: nil)
        @file = file
        @line = line
      end

      def mtime
        File.mtime(file)
      end

      def app_root
        exploded_path = Utils::Path.split(file)

        path = exploded_path[0...exploded_path.rindex(test_root_folder_name)]
        File.join(path)
      end

      def relative_test_path
        exploded_path = Utils::Path.split(file)
        path = exploded_path[exploded_path.rindex(test_root_folder_name)..-1]
        File.join(path)
      end

      def test_root_folder_name
        "test"
      end
    end

    class Collection < SimpleDelegator
      alias :results :__getobj__

      def file_count
        results.group_by(&:file).size
      end

      def one_example?
        examples_found? && results.size == 1
      end

      def examples_found?
        results.any?(&:line)
      end

      def last_edited
        results.sort_by(&:mtime).last
      end
    end

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
      return [] unless query.match(/^\//)

      relative_file_path = query.sub(Dir.pwd, '').sub(/^\//, '')
      [ Result.new(file: relative_file_path) ]
    end

    def examples_found_by_name
      @examples_found_by_name ||= full_regex_search(regex_pattern)
    end

    def files_found_by_file_name
      @files_found_by_file_name ||= searcher.find_files(query).select { |f| f.match(file_name_regex) }.map {|f| Result.new(file: f) }
    end

    def files_found_by_full_regex
      # we ignore the matched line since we don't know what to do with it
      @files_found_by_full_regex ||= full_regex_search(query).map {|t| Result.new(file: t.file) }
    end

    def full_regex_search(regex)
      searcher.grep(regex, file_pattern: file_name_pattern).map {|r| Result.new(file: r[:file], line: r[:line])}
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
  end
end


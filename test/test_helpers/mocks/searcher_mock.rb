require "test_helpers/mock"
require "test_launcher/search/git"

module TestLauncher
  class MemorySearcher < Mock
    class FileBuilder
      def path(path)
        @path = path
      end

      def contents(string)
        @lines = string.split("\n")
      end

      def mtime(time) # TODO: this doesn't work yet!
        @mtime = time
      end

      def to_file_mock
        FileMock.new(@path, @lines, @mtime)
      end
    end

    class FileMock
      attr_reader :path, :lines
      def initialize(path, lines, mtime)
        @path = path
        @lines = lines
        File.stubs(:mtime).with(path).returns(mtime)
        File.stubs(:exist?).returns(false)
        File.stubs(:exist?).with(path).returns(true)
      end

      def grep(regex)
        lines
          .each_with_index
          .map {|line_text, line_number|
            {
              file: path,
              line: line_text.strip,
              line_number: line_number + 1
            }
          }
          .select {|result|
            result[:line].match(regex)
          }
      end
    end

    mocks Search::Git

    def initialize
      yield(self)
    end

    def find_files(glob_pattern)
      file_mocks_for_pattern(glob_pattern).map(&:path)
    end

    def grep(regex, file_pattern: '*')
      file_mocks_for_pattern(file_pattern)
        .flat_map { |file|
          file.grep(regex)
        }
    end

    def mock_file
      file_builder = FileBuilder.new
      yield(file_builder)
      file_mocks << file_builder.to_file_mock
    end

    private

    def file_mocks_for_pattern(glob_pattern)
      regex = glob_pattern.gsub("*", ".*")
      file_mocks.select {|fm| fm.path.match(regex)}
    end

    def file_mocks
      @file_mocks ||= []
    end
  end
end

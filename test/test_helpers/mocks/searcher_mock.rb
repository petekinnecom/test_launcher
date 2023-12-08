require "test_helpers/mock"
require "test_launcher/search/git"

module TestLauncher
  class MemorySearcher < Mock
    class FileBuilder

      def initialize(dir)
        @dir = dir
      end

      def path(path = nil)
        return @path if path.nil?

        @path = File.join(@dir, path)
      end

      def contents(string)
        @lines = string.split("\n")
      end

      def mtime(time = nil) # TODO: this doesn't work yet!
        return @mtime if time.nil?

        @mtime = time
      end

      def to_file_mock
        tmp_path = Pathname.new(@path)
        FileUtils.mkdir_p(tmp_path.parent)
        FileUtils.touch(tmp_path)
        File.stubs(:mtime).with(tmp_path.to_s).returns(@mtime)

        FileMock.new(@path, @lines, @mtime, @dir)
      end
    end

    class FileMock
      attr_reader :path, :lines, :mtime, :dir
      def initialize(path, lines, mtime, dir)
        @path = path
        @lines = lines
        @mtime = mtime
        @dir = dir
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

      def relative_path
        Pathname.new(path).relative_path_from(Pathname.new(dir)).to_s
      end
    end

    mocks Search::Git

    attr_reader :dir
    def initialize(root: "/src")
      @dir = Dir.mktmpdir

      # mock the root directory
      mock_file do |f|
        f.path "/src/Gemfile"
      end

      yield(self)
    end

    def ls_files(glob_pattern)
      file_mocks_for_pattern(glob_pattern).map(&:path)
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
      file_builder = FileBuilder.new(dir)
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

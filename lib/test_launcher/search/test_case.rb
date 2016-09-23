require "test_launcher/utils/path"

module TestLauncher
  module Search
    class TestCase
      attr_reader :file, :example

      def self.from_search(file:, query: nil)
        new(file: file, example: query)
      end

      def initialize(file:, example: nil)
        @file = file
        @example = example
      end

      def is_example?
        !example.nil?
      end

      def mtime
        File.mtime(file)
      end

      def app_root
        path = exploded_path[0...exploded_path.rindex(test_root_folder_name)]
        File.join("/", path)
      end

      def relative_test_path
        path = exploded_path[exploded_path.rindex(test_root_folder_name)..-1]
        File.join(path)
      end

      def spring_enabled?
        File.exist?(File.join(app_root, "bin/spring"))
      end

      def runner
        raise NotImplementedError
      end

      def test_root_folder_name
        raise NotImplementedError
      end

      def exploded_path
        Utils::Path.split(file)
      end
    end
  end
end

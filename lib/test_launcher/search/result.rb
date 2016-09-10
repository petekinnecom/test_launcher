module TestLauncher
  module Search
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
  end
end

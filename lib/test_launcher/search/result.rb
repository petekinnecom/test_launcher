require "test_launcher/utils/path"

module TestLauncher
  module Search
    class Result
      attr_reader :file, :line, :test_root_folder_name

      def initialize(file:, line: nil, test_root_folder_name:)
        @file = file
        @line = line

        # This is not ideal.
        # What is some other way for this to work?
        # Needs to be configure by the specific framework
        # but it's a bummer to pass it through the SearchResults class
        @test_root_folder_name = test_root_folder_name
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
    end
  end
end

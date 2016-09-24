require "pathname"

module TestLauncher
  module Frameworks
    module Implementation
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
          @mtime ||= File.mtime(file)
        end

        def app_root
          path = exploded_path[0...exploded_path.rindex(test_root_folder_name)]
          File.join("/", path)
        end

        def test_root
          File.join(app_root, test_root_folder_name)
        end

        def relative_test_path
          path = exploded_path[exploded_path.rindex(test_root_folder_name)..-1]
          File.join(path)
        end

        def spring_enabled?
          [
            "bin/spring",
            "bin/testunit"
          ].any? {|f|
            File.exist?(File.join(app_root, f))
          }
        end

        def runner
          raise NotImplementedError
        end

        def test_root_folder_name
          raise NotImplementedError
        end

        def exploded_path
          Pathname.new(file).each_filename.to_a
        end
      end
    end
  end
end

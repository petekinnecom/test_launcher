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
          # TODO: untested - If we have more than one /test/ folder in the path, we search for a Gemfile or gemspec
          if exploded_path.select { test_root_folder_name }.size > 1
            exploded_path.each_with_index do |folder_name, i|
              next unless folder_name == test_root_folder_name

              root_path = File.join("/", exploded_path[0...i])
              if Dir.entries(root_path).any? {|e| e.match /Gemfile|gemspec/}
                return root_path
              end
            end
          end

          # default to our best guess
          path = exploded_path[0...exploded_path.rindex(test_root_folder_name)]
          File.join("/", path)
        end

        def test_root
          File.join(app_root, test_root_folder_name)
        end

        def spring_enabled?
          # TODO: move ENV reference to options hash
          return false if ENV['DISABLE_SPRING']

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

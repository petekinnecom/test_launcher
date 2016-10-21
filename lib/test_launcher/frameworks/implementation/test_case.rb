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
          if exploded_path.select { |folder| folder == test_root_folder_name }.size > 1
            candidates = exploded_path

            while !candidates.empty?
              if candidates.last == test_root_folder_name
                root_path = File.join("/", candidates[0..-2])
                return root_path if Dir.entries(root_path).any? {|e| e.match /Gemfile|gemspec/}
              end

              candidates.pop
            end
          end

          path = exploded_path[0...exploded_path.index(test_root_folder_name)]
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

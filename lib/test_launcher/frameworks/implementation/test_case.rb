require "pathname"

module TestLauncher
  module Frameworks
    module Implementation
      class TestCase
        attr_reader :file, :example, :request, :line_number

        def self.from_search(file:, query:, request:)
          new(file: file, example: query, request: request)
        end

        def initialize(file:, example: nil, request:, line_number: nil)
          @file = file
          @example = example
          @line_number = line_number
          @request = request
        end

        def is_example?
          !example.nil?
        end

        def mtime
          @mtime ||= File.mtime(file)
        end

        def app_root
          if exploded_path.select { |dir| dir == test_root_dir_name }.size > 1
            candidates = exploded_path

            while !candidates.empty?
              if candidates.last == test_root_dir_name
                root_path = File.join("/", candidates[0..-2])
                return root_path if Dir.entries(root_path).any? {|e| e.match /Gemfile|gemspec|mix.exs|config.ru/} # TODO: extract this
              end

              candidates.pop
            end
          end

          path = exploded_path[0...exploded_path.index(test_root_dir_name)]
          File.join("/", path)
        end

        def test_root
          File.join(app_root, test_root_dir_name)
        end

        def test_root_dir_name
          raise NotImplementedError
        end

        def exploded_path
          Pathname.new(file).each_filename.to_a
        end
      end
    end
  end
end

require 'pathname'

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

        def relative_file
          file.sub(/^#{File.join(app_root, '/')}/, '')
        end

        def app_root
          test_dir_parent = nil

          Pathname.new(file).parent.ascend do |path|
            if test_dir_parent.nil? && path.basename.to_s == test_root_dir_name
              test_dir_parent = path.parent.to_s
              next
            elsif test_dir_parent.nil?
              next
            elsif path.entries.any? { |e| e.to_s.match /Gemfile|gemspec|mix.exs|config.ru/ }
              return path.to_s
            end
          end

          test_dir_parent || Pathname.new(file).parent.to_s
        end

        def test_root
          File.join(app_root, test_root_dir_name)
        end

        def test_root_dir_name
          raise NotImplementedError
        end

        def exploded_path
          file.split("/")
        end
      end
    end
  end
end

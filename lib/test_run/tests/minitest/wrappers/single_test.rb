require "test_launcher/utils/path"

module TestLauncher
  module Tests
    module Minitest
      module Wrappers
        class SingleTest

          attr_reader :file, :name
          private :file, :name

          def initialize(file:, line:)
            @file = file
            @name = line[/\s*def\s+(.*)/, 1]
          end

          def to_command
            %{cd #{app_root} && ruby -I test #{relative_test_path} --name=/#{name}/}
          end

          def app_root
            exploded_path = Utils::Path.split(file)

            path = exploded_path[0...exploded_path.rindex("test")]
            File.join(path)
          end

          def relative_test_path
            exploded_path = Utils::Path.split(file)
            path = exploded_path[exploded_path.rindex("test")..-1]
            File.join(path)
          end
        end
      end
    end
  end
end

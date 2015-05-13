require "test_run/utils/path"

module TestLauncher
  module Tests
    module Minitest
      module Wrappers
        class SingleFile < Struct.new(:file)

          def to_command
            %{cd #{File.join(app_root)} && ruby -I test #{File.join(relative_test_path)}}
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

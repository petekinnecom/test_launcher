require "test_run/utils/path"

module TestLauncher
  module Tests
    module Minitest
      module Wrappers
        class MultipleRoots

          attr_reader :roots, :shell

          def initialize(files, shell)
            @shell = shell
            @roots = files.map {|f| SingleFile.new(f)}.group_by {|f| f.app_root}.map {|root, _files| SingleRoot.new(_files, shell)}
          end

          def to_command
            roots.map(&:to_command).join("; cd -;\n\n")
          end
        end
      end
    end
  end
end

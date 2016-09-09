require "test_launcher/utils/path"

module TestLauncher
  module Frameworks
    module Minitest
      module Wrappers
        class MultipleRoots

          attr_reader :roots, :shell

          def initialize(files, shell)
            @shell = shell
            @roots = files.map {|f| SingleFile.new(f)}.group_by {|f| f.app_root}.map {|root, _files| SingleRoot.new(_files, shell)}
          end

          def to_s
            roots.map(&:to_s).join("; cd -;\n\n")
          end
        end
      end
    end
  end
end

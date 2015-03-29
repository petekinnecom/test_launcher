require "test_run/tests/minitest/wrappers/single_root"
require "test_run/tests/minitest/wrappers/multiple_roots"

module TestRun
  module Tests
    module Minitest
      module Wrappers
        module MultipleFiles

          def self.wrap(files, shell)
            wrapper = MultipleRoots.new(files, shell)

            if wrapper.roots.size > 1
              wrapper
            else
              wrapper.roots.first
            end
          end
        end
      end
    end
  end
end

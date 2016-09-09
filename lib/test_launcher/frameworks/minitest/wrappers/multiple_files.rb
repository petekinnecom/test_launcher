require "test_launcher/frameworks/minitest/wrappers/single_root"
require "test_launcher/frameworks/minitest/wrappers/multiple_roots"

module TestLauncher
  module Frameworks
    module Minitest
      module Wrappers
        module MultipleFiles

          def self.wrap(files)
            wrapper = MultipleRoots.new(files)

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

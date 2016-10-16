require "delegate"

module TestLauncher
  module Frameworks
    module Implementation
      class Collection < SimpleDelegator
        alias :results :__getobj__

        def initialize(results:, run_all:)
          super(results)
          @run_all = run_all
        end

        def file_count
          results.group_by(&:file).size
        end

        def one_example?
          examples_found? && results.size == 1
        end

        def examples_found?
          results.any?(&:is_example?)
        end

        def last_edited
          results.sort_by(&:mtime).last
        end

        def run_all?
          @run_all
        end
      end
    end
  end
end

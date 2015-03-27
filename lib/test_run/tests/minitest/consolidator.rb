require "test_run/utils/path"

require "test_run/tests/minitest/wrappers/single_test"
require "test_run/tests/minitest/wrappers/single_file"
require "test_run/tests/minitest/wrappers/multiple_files"

module TestRun
  module Tests
    module Minitest
      class Consolidator < Struct.new(:find_results)

        def self.consolidate(find_results)
          new(find_results).consolidate
        end

        def consolidate
          if find_results.empty?
            puts "no results"
            exit
          end

          if one_result?
            Wrappers::SingleTest.new(find_results.first).to_command
          elsif one_test_file?
            Wrappers::SingleFile.new(find_results.first[:file]).to_command
          else
            Wrappers::MultipleFiles.wrap(find_results.map {|r| r[:file] }).to_command
          end
        end

        def one_test_file?
          find_results.group_by {|f| f[:file]}.size == 1
        end

        def one_result?
          one_test_file? && find_results.first[:line]
        end

      end
    end
  end
end

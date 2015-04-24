require "test_run/utils/path"

require "test_run/tests/minitest/wrappers/single_test"
require "test_run/tests/minitest/wrappers/single_file"
require "test_run/tests/minitest/wrappers/multiple_files"

module TestRun
  module Tests
    module Minitest
      class Consolidator < Struct.new(:search_results, :shell, :run_all)

        def self.consolidate(*args)
          new(*args).consolidate
        end

        def consolidate
          if search_results.empty?
            shell.warn "Could not find any tests."
            exit
          end

          if test_methods_found? && one_result?
            shell.notify "Found 1 test method."
            Wrappers::SingleTest.new(search_results.first)
          elsif test_methods_found? && same_file?
            shell.notify "Multiple test methods match in 1 file."
            Wrappers::SingleFile.new(search_results.first[:file])
          elsif test_methods_found? && run_last_edited?
            shell.notify "Found #{search_results.size} test methods in #{file_count} files."
            shell.notify "Running most recently edited. Run with '--all' to run all the tests."
            Wrappers::SingleTest.new(last_edited)
          elsif files_found? && same_file?
            shell.notify "Found 1 file."
            Wrappers::SingleFile.new(search_results.first[:file])
          elsif files_found? && run_last_edited?
            shell.notify "Found #{file_count} files."
            shell.notify "Running most recently edited. Run with '--all' to run all the tests."
            Wrappers::SingleFile.new(last_edited[:file])
          else
            shell.notify "Found #{file_count} files."
            Wrappers::MultipleFiles.wrap(search_results.map {|r| r[:file] }, shell)
          end
        end

        def same_file?
           file_count == 1
        end

        def one_result?
          same_file? && search_results.first[:line]
        end

        def test_methods_found?
          !! search_results.first[:line]
        end

        def files_found?
          ! test_methods_found?
        end

        def run_last_edited?
          ! run_all
        end

        def last_edited
          search_results.sort_by {|r| File.mtime(r[:file])}.last
        end

        def file_count
          search_results.group_by {|f| f[:file]}.size
        end
      end
    end
  end
end

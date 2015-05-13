require "test_run/utils/path"

require "test_run/tests/minitest/wrappers/single_test"
require "test_run/tests/minitest/wrappers/single_file"
require "test_run/tests/minitest/wrappers/multiple_files"
require "test_run/utils/pluralize"

module TestLauncher
  module Tests
    module Minitest
      class Consolidator < Struct.new(:search_results, :shell, :run_all)
        include Utils::Pluralize

        def self.consolidate(*args)
          new(*args).consolidate
        end

        def consolidate
          if search_results.empty?
            shell.warn "Could not find any tests."
            exit
          end

          if methods_found? && one_result?
            shell.notify "Found #{methods_count_phrase} in #{file_count_phrase}."
            Wrappers::SingleTest.new(search_results.first)
          elsif methods_found? && same_file?
            shell.notify "Multiple test methods match in 1 file."
            Wrappers::SingleFile.new(search_results.first[:file])
          elsif methods_found? && run_last_edited?
            shell.notify "Found #{methods_count_phrase} in #{file_count_phrase}."
            shell.notify "Running most recently edited. Run with '--all' to run all the tests."
            Wrappers::SingleTest.new(last_edited)
          elsif files_found? && same_file?
            shell.notify "Found #{file_count_phrase}."
            Wrappers::SingleFile.new(search_results.first[:file])
          elsif files_found? && run_last_edited?
            shell.notify "Found #{file_count_phrase}."
            shell.notify "Running most recently edited. Run with '--all' to run all the tests."
            Wrappers::SingleFile.new(last_edited[:file])
          else
            shell.notify "Found #{file_count_phrase}."
            Wrappers::MultipleFiles.wrap(search_results.map {|r| r[:file] }, shell)
          end
        end

        def same_file?
           file_count == 1
        end

        def one_result?
          same_file? && search_results.first[:line]
        end

        def methods_found?
          !! search_results.first[:line]
        end

        def files_found?
          ! methods_found?
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

        def methods_count_phrase
          pluralize(search_results.size, "test method")
        end

        def file_count_phrase
          pluralize(file_count, "file")
        end
      end
    end
  end
end

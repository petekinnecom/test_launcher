module TestLauncher
  module Frameworks
    module Implementation
      class Consolidator < Struct.new(:search_results, :shell, :runner)

        def self.consolidate(*args)
          new(*args).consolidate
        end

        def consolidate
          if search_results.empty?
            nil
          elsif one_example?
            shell.notify "Found #{methods_count_phrase} in #{file_count_phrase}."
            runner.single_example(search_results.first, exact_match: true)
          elsif examples_found? && same_file?
            shell.notify "Multiple test methods match in 1 file."
            runner.single_example(search_results.first)
          elsif examples_found? && run_last_edited?
            shell.notify "Found #{methods_count_phrase} in #{file_count_phrase}."
            shell.notify "Running most recently edited. Run with '--all' to run all the tests."
            runner.single_example(last_edited)
          elsif files_found? && same_file?
            shell.notify "Found #{file_count_phrase}."
            runner.single_file(search_results.first)
          elsif files_found? && run_last_edited?
            shell.notify "Found #{file_count_phrase}."
            shell.notify "Running most recently edited. Run with '--all' to run all the tests."
            runner.single_file(last_edited)
          else
            shell.notify "Found #{file_count_phrase}."
            runner.multiple_files(search_results.uniq {|sr| sr.file})
          end
        end

        def same_file?
          file_count == 1
        end

        def one_example?
          search_results.one_example?
        end

        def examples_found?
          search_results.examples_found?
        end

        def files_found?
          ! examples_found?
        end

        def run_last_edited?
          ! search_results.run_all?
        end

        def last_edited
          search_results.last_edited
        end

        def file_count
          search_results.file_count
        end

        def methods_count_phrase
          pluralize(search_results.size, "test method")
        end

        def file_count_phrase
          pluralize(file_count, "file")
        end

        def pluralize(count, singular)
          phrase = "#{count} #{singular}"
          if count == 1
            phrase
          else
            "#{phrase}s"
          end
        end
      end
    end
  end
end

require "test_launcher/frameworks/implementation/test_case"

module TestLauncher
  module Frameworks
    module Base
      class Searcher < Struct.new(:raw_searcher)
        def test_files(query)
          raw_searcher
            .find_files(query)
            .select {|f| f.match(file_name_regex)}
        end

        def examples(query)
          grep(example_name_regex(query))
        end

        def grep(regex)
          raw_searcher.grep(regex, file_pattern: file_name_pattern)
        end

        def by_line(file_pattern, line_number)
          raise NotImplementedError
        end

        private

        def file_name_regex
          raise NotImplementedError
        end

        def file_name_pattern
          raise NotImplementedError
        end

        def example_name_regex(query)
          raise NotImplementedError
        end
      end

      class Runner
        def single_example(test_case)
          raise NotImplementedError
        end

        def multiple_examples_same_file(test_cases)
          raise NotImplementedError
        end

        def one_or_more_files(test_cases)
          raise NotImplementedError
        end

        def single_file(test_case)
          one_or_more_files([test_case])
        end

        def multiple_files(collection)
          collection
            .group_by(&:app_root)
            .map { |_root, test_cases| one_or_more_files(test_cases) }
            .join("; cd -;\n\n")
        end
      end

      class TestCase < Implementation::TestCase
        def test_root_dir_name
          # directory where tests are found
          raise NotImplementedError
        end
      end
    end
  end
end

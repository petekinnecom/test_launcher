require "test_launcher/frameworks/implementation/locator"
require "test_launcher/frameworks/implementation/test_case"
require "test_launcher/frameworks/implementation/consolidator"

module TestLauncher
  module Frameworks
    module Base
      class Locator < Implementation::Locator
        def file_name_regex
          # for ruby to match on file names
          raise NotImplementedError
        end

        def file_name_pattern
          # for bash to match on file names
          raise NotImplementedError
        end

        def regex_pattern
          # to match on examples
          raise NotImplementedError
        end
      end

      class Runner
        def single_example(test_case)
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

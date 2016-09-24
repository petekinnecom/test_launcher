require "test_launcher/frameworks/implementation/locator"
require "test_launcher/frameworks/implementation/test_case"
require "test_launcher/frameworks/implementation/consolidator"

module TestLauncher
  module Frameworks
    module Base
      class SearchResults < Implementation::Locator
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
        def single_example(result)
          raise NotImplementedError
        end

        def one_or_more_files(results)
          raise NotImplementedError
        end

        def single_file(result)
          one_or_more_files([result])
        end

        def multiple_files(collection)
          collection
            .group_by(&:app_root)
            .map { |_root, results| one_or_more_files(results) }
            .join("; cd -;\n\n")
        end
      end

      class TestCase < Implementation::TestCase
        def test_root_folder_name
          # directory where tests are found
          raise NotImplementedError
        end
      end
    end
  end
end

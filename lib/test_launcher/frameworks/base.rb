require "test_launcher/search/base"

module TestLauncher
  module Frameworks
    module Base
      class SearchResults < Search::Base
        def file_name_regex
          raise NotImplementedError
        end

        def file_name_pattern
          raise NotImplementedError
        end

        def regex_pattern
          raise NotImplementedError
        end
      end
    end
  end
end

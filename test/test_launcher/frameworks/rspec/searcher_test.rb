require "test_helper"
require "test_helpers/mocks"
require "test_launcher/search/git"
require "test_launcher/frameworks/rspec"

module TestLauncher
  module Frameworks
    module RSpec
      class SearcherTest < ::TestCase
        include DefaultMocks

        class RawSearcherMock < Mock
          mocks Search::Git

          impl :find_files do |pattern|
            case pattern
            when "not_found_spec.rb"
              []
            when "single_spec.rb"
              ["spec/test_launcher/single_spec.rb"]
            when "non_test_file.rb"
              ["non_test_file.rb"]
            when "multiple_spec.rb"
              ["spec/dir/1_multiple_spec.rb", "spec/dir/2_multiple_spec.rb"]
            else
              raise "unmocked search: #{pattern}"
            end
          end
        end

        def searcher
          @searcher ||= Searcher.new(RawSearcherMock.new)
        end

        def test_by_line__file_not_found
          assert_equal [], searcher.by_line("not_found_spec.rb", 1)
        end

        def test_by_line__file_is_not_test_file
          assert_equal [], searcher.by_line("non_test_file.rb", 1)
        end

        def test_by_line__file_is_found
          expected_result = [{
            file: "spec/test_launcher/single_spec.rb",
            line_number: 8
          }]

          assert_equal expected_result, searcher.by_line("single_spec.rb", 8)
        end
      end
    end
  end
end

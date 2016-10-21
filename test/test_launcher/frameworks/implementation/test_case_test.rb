require 'test_helper'

module TestLauncher
  module Frameworks
    module Implementation
      class DummyTestCaseTest < ::TestCase
        class DummyTestCase < Implementation::TestCase
          def test_root_folder_name
            "test"
          end
        end

        def test_app_root__one_test_folder
          test_case = DummyTestCase.new(file: "/path/root/test/thing_test.rb")

          assert_equal "/path/root", test_case.app_root
        end

        def test_app_root__multiple_test_folders__find_gemfile
          test_case = DummyTestCase.new(file: "/path/root/test/inline_gem/test/thing_test.rb")

          Dir.stubs(:entries).with("/path/root").returns([".", "..", "Gemfile", "other_stuff.rb"])
          Dir.stubs(:entries).with("/path/root/test/inline_gem").returns([".", "..", "other_stuff.rb"])

          assert_equal "/path/root", test_case.app_root
        end

        def test_app_root__multiple_test_folders__find_gemspec
          test_case = DummyTestCase.new(file: "/path/root/test/inline_gem/test/thing_test.rb")

          Dir.stubs(:entries).with("/path/root").returns([".", "..", "gem.gemspec", "other_stuff.rb"])
          Dir.stubs(:entries).with("/path/root/test/inline_gem").returns([".", "..", "other_stuff.rb"])

          assert_equal "/path/root", test_case.app_root
        end

        def test_app_root__multiple_test_folders__prefers_deeply_nested_folders
          test_case = DummyTestCase.new(file: "/path/root/test/inline_gem/test/thing_test.rb")

          Dir.stubs(:entries).with("/path/root").returns(["Gemfile"])
          Dir.stubs(:entries).with("/path/root/test/inline_gem").returns(["Gemfile"])

          assert_equal "/path/root/test/inline_gem", test_case.app_root
        end

        def test_app_root__multiple_test_folders__finds_no_info__defaults_outward
          test_case = DummyTestCase.new(file: "/path/root/test/inline_gem/test/thing_test.rb")

          Dir.stubs(:entries).with("/path/root").returns([".", ".."])
          Dir.stubs(:entries).with("/path/root/test/inline_gem").returns([".", ".."])

          assert_equal "/path/root", test_case.app_root
        end
      end
    end
  end
end

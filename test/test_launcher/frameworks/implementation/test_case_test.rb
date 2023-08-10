require "test_helper"
require "test_launcher/frameworks/implementation/test_case"


module TestLauncher
  module Frameworks
    module Implementation
      class TestCaseTest < ::TestCase
        class DummyTestCase < Implementation::TestCase
          def initialize(file:)
            super(file: file, request: nil)
          end

          def test_root_dir_name
            "test"
          end
        end

        def test_app_root__one_test_dir
          test_case = DummyTestCase.new(file: "/path/root/test/thing_test.rb")

          Dir.stubs(:entries).with("/").returns([".", ".."])
          Dir.stubs(:entries).with("/path").returns([".", ".."])
          Dir.stubs(:entries).with("/path/root").returns([".", ".."])

          assert_equal "/path/root", test_case.app_root
        end

        def test_app_root__multiple_test_dirs__find_gemfile
          test_case = DummyTestCase.new(file: "/path/root/test/inline_gem/test/thing_test.rb")

          Dir.stubs(:entries).with("/path/root").returns([".", "..", "Gemfile", "other_stuff.rb"])
          Dir.stubs(:entries).with("/path/root/test").returns([".", ".."])
          Dir.stubs(:entries).with("/path/root/test/inline_gem").returns([".", "..", "other_stuff.rb"])

          assert_equal "/path/root", test_case.app_root
        end

        def test_app_root__multiple_test_dirs__find_gemspec
          test_case = DummyTestCase.new(file: "/path/root/test/inline_gem/test/thing_test.rb")

          Dir.stubs(:entries).with("/path/root").returns([".", "..", "gem.gemspec", "other_stuff.rb"])
          Dir.stubs(:entries).with("/path/root/test").returns([".", "..", "other_stuff.rb"])
          Dir.stubs(:entries).with("/path/root/test/inline_gem").returns([".", "..", "other_stuff.rb"])

          assert_equal "/path/root", test_case.app_root
        end

        def test_app_root__multiple_test_dirs__find_configru
          test_case = DummyTestCase.new(file: "/path/root/test/dummy/test/thing_test.rb")

          Dir.stubs(:entries).with("/path/root").returns([".", "..", "gem.gemspec", "other_stuff.rb"])
          Dir.stubs(:entries).with("/path/root/test").returns([".", "..", "other_stuff.rb"])
          Dir.stubs(:entries).with("/path/root/test/dummy").returns([".", "..", "config.ru"])

          assert_equal "/path/root/test/dummy", test_case.app_root
        end

        def test_app_root__multiple_test_dirs__prefers_deeply_nested_dirs
          test_case = DummyTestCase.new(file: "/path/root/test/inline_gem/test/thing_test.rb")

          Dir.stubs(:entries).with("/path/root").returns(["Gemfile"])
          Dir.stubs(:entries).with("/path/root/test/inline_gem").returns(["Gemfile"])

          assert_equal "/path/root/test/inline_gem", test_case.app_root
        end

        def test_app_root__multiple_test_dirs__finds_no_info__defaults_outward
          test_case = DummyTestCase.new(file: "/path/root/test/inline_gem/test/thing_test.rb")

          Dir.stubs(:entries).with("/").returns([".", ".."])
          Dir.stubs(:entries).with("/path").returns([".", ".."])
          Dir.stubs(:entries).with("/path/root").returns([".", ".."])
          Dir.stubs(:entries).with("/path/root/test").returns([".", ".."])
          Dir.stubs(:entries).with("/path/root/test/inline_gem").returns([".", ".."])

          assert_equal "/path/root/test/inline_gem", test_case.app_root
        end

        def test_app_root__always_checks_for_gemfile
          test_case = DummyTestCase.new(file: "/path/root/stuff/inline_gem/test/more/thing_test.rb")

          Dir.stubs(:entries).with("/path/root").returns([".", "..", "Gemfile"])
          Dir.stubs(:entries).with("/path/root/stuff").returns([".", ".."])
          Dir.stubs(:entries).with("/path/root/stuff/inline_gem").returns([".", ".."])

          assert_equal "/path/root", test_case.app_root
        end

        def test_app_root__cant_find_test_dir_or_anything_defaults_to_parent
          test_case = DummyTestCase.new(file: "/path/root/stuff/inline_gem/not_test/more/thing_test.rb")

          assert_equal "/path/root/stuff/inline_gem/not_test/more", test_case.app_root
        end
      end
    end
  end
end

require "test_helper"
require "test_run/tests/minitest/consolidator"

module TestRun
  module Tests
    module Minitest

      class ConsolidatorTest < TestCase

        def test_single_test_method__no_sub_dir
          search_results = [
            {
              file: "test/dir/file_test.rb",
              line: "def test_run",
            },
          ]

          consolidator = Consolidator.new(search_results, dummy_shell, false)
          assert_equal "cd . && ruby -I test test/dir/file_test.rb --name=/test_run/", consolidator.consolidate.to_command
          assert_notified "Found 1 test method in 1 file."
        end

        def test_single_test_method__with_sub_dir
          search_results = [
            {
              file: "engines/lawnmower/test/dir/file_test.rb",
              line: "def test_run",
            }
          ]

          consolidator = Consolidator.new(search_results, dummy_shell, false)
          assert_equal "cd ./engines/lawnmower && ruby -I test test/dir/file_test.rb --name=/test_run/", consolidator.consolidate.to_command
          assert_notified "Found 1 test method in 1 file."
        end

        def test_multiple_test_methods_in_same_file
          search_results = [
            {
              file: "test/dir/file_test.rb",
              line: "def test_run",
            },
            {
              file: "test/dir/file_test.rb",
              line: "def test_run_again",
            },
            {
              file: "test/dir/file_test.rb",
              line: "def test_run_some_more",
            },
          ]

          consolidator = Consolidator.new(search_results, dummy_shell, false)

          assert_equal "cd . && ruby -I test test/dir/file_test.rb --name=/test_run/", consolidator.consolidate.to_command
          assert_notified "Found 3 test methods in 1 file."
        end

        def test_multiple_test_methods_in_different_files__last_edited
          search_results = [
            {
              file: "test/dir/file_test.rb",
              line: "def test_run",
            },
            {
              file: "test/other_dir/different_test.rb",
              line: "def test_run",
            },
          ]

          consolidator = Consolidator.new(search_results, dummy_shell, false)

          File.expects(:mtime).with("test/dir/file_test.rb").returns(Time.new(2014, 01, 01))
          File.expects(:mtime).with("test/other_dir/different_test.rb").returns(Time.new(2013, 01, 01))

          assert_equal "cd . && ruby -I test test/dir/file_test.rb --name=/test_run/", consolidator.consolidate.to_command
          assert_notified "Found 2 test methods in 2 files."
        end

        def test_multiple_test_methods_in_different_files__run_all__same_root
          search_results = [
            {
              file: "test/dir/file_test.rb",
              line: "def test_run",
            },
            {
              file: "test/other_dir/different_test.rb",
              line: "def test_run",
            },
          ]

          consolidator = Consolidator.new(search_results, dummy_shell, true)

          assert_equal %{cd . && ruby -I test -e 'ARGV.each { |file| require(Dir.pwd + "/" + file) }' test/dir/file_test.rb test/other_dir/different_test.rb}, consolidator.consolidate.to_command
          assert_notified "Found 2 files."
        end

        def test_multiple_test_methods_in_different_files__run_all__different_roots
          search_results = [
            {
              file: "engine1/test/dir/file_test.rb",
              line: "def test_run",
            },
            {
              file: "engine2/root2/test/other_dir/different_test.rb",
              line: "def test_run",
            },
          ]

          consolidator = Consolidator.new(search_results, dummy_shell, true)
          expected = <<-SHELL
          cd ./engine1 && ruby -I test -e 'ARGV.each { |file| require(Dir.pwd + \"/\" + file) }' test/dir/file_test.rb; cd -;

          cd ./engine2/root2 && ruby -I test -e 'ARGV.each { |file| require(Dir.pwd + \"/\" + file) }' test/other_dir/different_test.rb
          SHELL

          assert_paragraphs_equal expected, consolidator.consolidate.to_command
          assert_notified "Found 2 files."
        end

        def test_one_file_found
          search_results = [
            {
              file: "engine1/test/dir/file_test.rb",
            },
          ]

          consolidator = Consolidator.new(search_results, dummy_shell, true)

          assert_equal "cd ./engine1 && ruby -I test test/dir/file_test.rb", consolidator.consolidate.to_command
          assert_notified "Found 1 file."
        end

        def test_multiple_files__last_edited
          search_results = [
            {
              file: "test/dir/file_test.rb",
            },
            {
              file: "test/other_dir/different_test.rb",
            },
          ]

          consolidator = Consolidator.new(search_results, dummy_shell, false)

          File.expects(:mtime).with("test/dir/file_test.rb").returns(Time.new(2014, 01, 01))
          File.expects(:mtime).with("test/other_dir/different_test.rb").returns(Time.new(2013, 01, 01))

          assert_equal "cd . && ruby -I test test/dir/file_test.rb", consolidator.consolidate.to_command
          assert_notified "Found 2 files."
        end

        def test_multiple_files__run_all__same_root
          search_results = [
            {
              file: "engine1/test/dir/file_test.rb",
            },
            {
              file: "engine1/test/other_dir/different_test.rb",
            },
          ]

          consolidator = Consolidator.new(search_results, dummy_shell, true)
          expected = %{cd ./engine1 && ruby -I test -e 'ARGV.each { |file| require(Dir.pwd + \"/\" + file) }' test/dir/file_test.rb test/other_dir/different_test.rb}

          assert_equal expected, consolidator.consolidate.to_command
          assert_notified "Found 2 files."
        end

        def test_multiple_files__run_all__different_roots
          search_results = [
            {
              file: "engine1/test/dir/file_test.rb",
            },
            {
              file: "engine2/root2/test/other_dir/different_test.rb",
            },
          ]

          consolidator = Consolidator.new(search_results, dummy_shell, true)
          expected = <<-SHELL
          cd ./engine1 && ruby -I test -e 'ARGV.each { |file| require(Dir.pwd + \"/\" + file) }' test/dir/file_test.rb; cd -;

          cd ./engine2/root2 && ruby -I test -e 'ARGV.each { |file| require(Dir.pwd + \"/\" + file) }' test/other_dir/different_test.rb
          SHELL

          assert_paragraphs_equal expected, consolidator.consolidate.to_command
          assert_notified "Found 2 files."
        end
      end
    end
  end
end

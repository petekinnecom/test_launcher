require "test_helper"
require "test_helpers/integration_helper"

module TestLauncher
  class ExUnitIntegrationTest < TestCase
    include IntegrationHelper

    def launch(query, env: {}, searcher:, shell: shell_mock)
      query += " --framework ex_unit "
      shell.reset
      CLI.launch(query.split(" "), env, shell: shell, searcher: searcher)
    end

    def test__by_example__single_method
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1_test.exs"
          f.contents <<-RB
            defmodule MyApp.File1Test do
              test "test_name" do
              end
            end
          RB
        end
      end

      launch("test_name", searcher: searcher)
      assert_equal "cd /src && mix test /src/test/file_1_test.exs:2", shell_mock.recall_exec

      launch("n", searcher: searcher)
      assert_equal "cd /src && mix test /src/test/file_1_test.exs:2", shell_mock.recall_exec
    end

    def test__by_example__multiple_methods__same_file
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1_test.exs"
          f.contents <<-RB
            defmodule File1Test do
              test "test_name_1" do
              end

              test "test_name_2" do
              end
            end
          RB
        end
      end

      launch("name_", searcher: searcher)
      assert_equal "cd /src && mix test /src/test/file_1_test.exs", shell_mock.recall_exec
    end

    def test__by_example__multiple_methods__different_files
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1_test.exs"
          f.mtime Time.new(2014, 01, 01, 00, 00, 00)
          f.contents <<-RB
            test "test_name_1" do
            test "test_name_2" do
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/test/file_2_test.exs"
          f.mtime Time.new(2015, 01, 01, 00, 00, 00)
          f.contents <<-RB
            test "test_name_1" do
            test "test_name_2" do
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/test/file_3_test.exs"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
          f.contents <<-RB
            test "test_name_2" do
          RB
        end
      end

      launch("name_1", searcher: searcher)
      assert_equal "cd /src && mix test /src/test/file_2_test.exs:1", shell_mock.recall_exec

      launch("name_2", searcher: searcher)
      assert_equal "cd /src && mix test /src/test/file_2_test.exs:2", shell_mock.recall_exec

      launch("name_1 --all", searcher: searcher)
      assert_equal "cd /src && mix test /src/test/file_1_test.exs /src/test/file_2_test.exs", shell_mock.recall_exec

      launch("name_2 --all", searcher: searcher)
      assert_equal "cd /src && mix test /src/test/file_1_test.exs /src/test/file_2_test.exs /src/test/file_3_test.exs", shell_mock.recall_exec
    end

    def test__by_filename
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1_test.exs"
          f.contents ""
        end
      end

      launch("file_1", searcher: searcher)
      assert_equal "cd /src && mix test /src/test/file_1_test.exs", shell_mock.recall_exec

      launch("file_1_test.exs", searcher: searcher)
      assert_equal "cd /src && mix test /src/test/file_1_test.exs", shell_mock.recall_exec

      launch("/file_1", searcher: searcher)
      assert_equal "cd /src && mix test /src/test/file_1_test.exs", shell_mock.recall_exec

      launch(".exs", searcher: searcher)
      assert_equal "cd /src && mix test /src/test/file_1_test.exs", shell_mock.recall_exec

      launch("/src/test/file_1", searcher: searcher)
      assert_equal "cd /src && mix test /src/test/file_1_test.exs", shell_mock.recall_exec

      launch("src/test/file_1", searcher: searcher)
      assert_equal "cd /src && mix test /src/test/file_1_test.exs", shell_mock.recall_exec

      launch("st/file_1", searcher: searcher)
      assert_equal "cd /src && mix test /src/test/file_1_test.exs", shell_mock.recall_exec
    end

    def test__by_filename__multiple_files_found
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1_test.exs"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
        end

        searcher.mock_file do |f|
          f.path "/src/test/file_2_test.exs"
          f.mtime Time.new(2015, 01, 01, 00, 00, 00)
        end

        searcher.mock_file do |f|
          f.path "/src/test/file_3_test.exs"
          f.mtime Time.new(2014, 01, 01, 00, 00, 00)
        end

        searcher.mock_file do |f|
          f.path "/src/test/other_test.exs"
        end
      end

      launch("file_1", searcher: searcher)
      assert_equal "cd /src && mix test /src/test/file_1_test.exs", shell_mock.recall_exec

      launch("file", searcher: searcher)
      assert_equal "cd /src && mix test /src/test/file_2_test.exs", shell_mock.recall_exec

      launch("file --all", searcher: searcher)
      assert_equal "cd /src && mix test /src/test/file_1_test.exs /src/test/file_2_test.exs /src/test/file_3_test.exs", shell_mock.recall_exec
    end

    def test__by_filename__preferred_over_regex_and_test_name_matches
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1_test.exs"
          f.contents <<-RB
            test "test_name" do
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/test/name_test.exs"
        end

        searcher.mock_file do |f|
          f.path "/src/test/other_test.exs"
          f.contents <<-RB
            regex will match name_test
          RB
        end
      end

      launch("name_test", searcher: searcher)
      assert_equal "cd /src && mix test /src/test/name_test.exs", shell_mock.recall_exec
    end

    def test__by_multiple_filenames__multiple_files_found
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1_test.exs"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
          f.contents ""
        end

        searcher.mock_file do |f|
          f.path "/src/test/file_2_test.exs"
          f.mtime Time.new(2015, 01, 01, 00, 00, 00)
          f.contents ""
        end

        searcher.mock_file do |f|
          f.path "/src/test/file_3_test.exs"
          f.mtime Time.new(2014, 01, 01, 00, 00, 00)
          f.contents ""
        end

        searcher.mock_file do |f|
          f.path "/src/test/other_test.exs"
          f.contents ""
        end
      end

      launch("file_1 file_2", searcher: searcher)
      assert_equal "cd /src && mix test /src/test/file_1_test.exs /src/test/file_2_test.exs", shell_mock.recall_exec

      launch("file_1 file", searcher: searcher)
      assert_equal "cd /src && mix test /src/test/file_1_test.exs /src/test/file_2_test.exs /src/test/file_3_test.exs", shell_mock.recall_exec

      # If multiple queries are submitted but not all of them match,
      # then what should we do? For now, we assume that it's only
      # considered a match if each query term matches at least one
      # or more files.
      launch("file_1 gibberish", searcher: searcher)
      assert_equal nil, shell_mock.recall_exec
    end

    def test__by_regex__one_match
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1_test.exs"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
          f.contents <<-RB
            regex match 1
            regex match 2
            regex match 3
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/test/file_2_test.exs"
          f.mtime Time.new(2015, 01, 01, 00, 00, 00)
          f.contents <<-RB
            regex match 1
            regex match 2
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/test/file_3_test.exs"
          f.mtime Time.new(2014, 01, 01, 00, 00, 00)
          f.contents <<-RB
            regex match 1
            regex match 3
          RB
        end
      end

      launch("regex match 1", searcher: searcher)
      assert_equal "cd /src && mix test /src/test/file_2_test.exs", shell_mock.recall_exec

      launch("regex match 3", searcher: searcher)
      assert_equal "cd /src && mix test /src/test/file_3_test.exs", shell_mock.recall_exec

      launch("regex match", searcher: searcher)
      assert_equal "cd /src && mix test /src/test/file_2_test.exs", shell_mock.recall_exec

      launch("regex match --all", searcher: searcher)
      assert_equal "cd /src && mix test /src/test/file_1_test.exs /src/test/file_2_test.exs /src/test/file_3_test.exs", shell_mock.recall_exec
    end

    def test__by_example__handles_regex_for_example_name
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1_test.exs"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
          f.contents <<-RB
            test "test_name_1" do
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/test/file_2_test.exs"
          f.mtime Time.new(2015, 01, 01, 00, 00, 00)
          f.contents <<-RB
            test "test_name_2" do
          RB
        end
      end

      launch("test_name_1x?", searcher: searcher)
      assert_equal "cd /src && mix test /src/test/file_1_test.exs:1", shell_mock.recall_exec

      launch("test_name_2|test_name_1", searcher: searcher)
      assert_equal "cd /src && mix test /src/test/file_2_test.exs:1", shell_mock.recall_exec

      launch('test_name_\d', searcher: searcher)
      assert_equal "cd /src && mix test /src/test/file_2_test.exs:1", shell_mock.recall_exec

      launch('test_name_\d --all', searcher: searcher)
      assert_equal "cd /src && mix test /src/test/file_1_test.exs /src/test/file_2_test.exs", shell_mock.recall_exec
    end

    def test__not_found
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1_test.exs"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
          f.contents <<-RB
            some stuff
          RB
        end
      end

      launch("gibberish", searcher: searcher)
      assert_equal nil, shell_mock.recall_exec
    end

    def test__different_roots
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1_test.exs"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
          f.contents <<-RB
            test "test_name_1" do
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/test/file_2_test.exs"
          f.mtime Time.new(2015, 01, 01, 00, 00, 00)
          f.contents <<-RB
            test "test_name_2" do
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/inline/project/test/file_1_test.exs"
          f.mtime Time.new(2014, 01, 01, 00, 00, 00)
          f.contents <<-RB
            test "test_name_1" do
          RB
        end
      end

      launch("test_name_1", searcher: searcher)
      assert_equal "cd /src/inline/project && mix test /src/inline/project/test/file_1_test.exs:1", shell_mock.recall_exec

      launch("test_name_1 --all", searcher: searcher)
      assert_equal "cd /src && mix test /src/test/file_1_test.exs; cd -;\n\ncd /src/inline/project && mix test /src/inline/project/test/file_1_test.exs", shell_mock.recall_exec

      launch("file --all", searcher: searcher)
      assert_equal "cd /src && mix test /src/test/file_1_test.exs /src/test/file_2_test.exs; cd -;\n\ncd /src/inline/project && mix test /src/inline/project/test/file_1_test.exs", shell_mock.recall_exec

      launch("file_1", searcher: searcher)
      assert_equal "cd /src/inline/project && mix test /src/inline/project/test/file_1_test.exs", shell_mock.recall_exec

      launch("file_1 --all", searcher: searcher)
      assert_equal "cd /src && mix test /src/test/file_1_test.exs; cd -;\n\ncd /src/inline/project && mix test /src/inline/project/test/file_1_test.exs", shell_mock.recall_exec
    end

    def test__by_line_number__just_passes_through_to_ex_unit
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1_test.exs"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
          f.contents ""
        end
      end

      launch("file_1_test.exs:1", searcher: searcher)
      assert_equal "cd /src && mix test /src/test/file_1_test.exs:1", shell_mock.recall_exec

      launch("file_1_test.exs:273", searcher: searcher)
      assert_equal "cd /src && mix test /src/test/file_1_test.exs:273", shell_mock.recall_exec
    end

    def test__by_line_number__multiple_files
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1_test.exs"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
          f.contents ""
        end

        searcher.mock_file do |f|
          f.path "/src/inline/project/test/file_1_test.exs"
          f.mtime Time.new(2014, 01, 01, 00, 00, 00)
          f.contents ""
        end
      end

      launch("file_1_test.exs:1", searcher: searcher)
      assert_equal "cd /src/inline/project && mix test /src/inline/project/test/file_1_test.exs:1", shell_mock.recall_exec
    end

    def test__rerun
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1_test.exs"
          f.mtime Time.new(2014, 01, 01, 00, 00, 00)
        end
        searcher.mock_file do |f|
          f.path "/src/test/file_2_test.exs"
          f.mtime Time.new(2015, 01, 01, 00, 00, 00)
        end
      end

history_shell = Shell::HistoryRunner.new(shell: shell_mock, history_path: File.expand_path(File.join(__dir__, '../../tmp/test_history.log')))

      launch("file_1_test.exs", searcher: searcher, shell: history_shell)
      assert_equal "cd /src && mix test /src/test/file_1_test.exs", history_shell.recall_exec

      launch("--rerun", searcher: searcher, shell: history_shell)
      assert_equal "cd /src && mix test /src/test/file_1_test.exs", history_shell.recall_exec
    end
  end
end

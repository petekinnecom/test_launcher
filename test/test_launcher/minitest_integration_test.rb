require "test_helper"
require "test_helpers/integration_helper"

module TestLauncher
  class MinitestIntegrationTest < TestCase
    include IntegrationHelper

    def launch(query, env: {}, searcher:, shell: shell_mock)
      query += " --framework minitest "
      shell.reset
      CLI.launch(query.split(" "), env, shell: shell, searcher: searcher)
    end

    def test__by_example__single_method
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/class_1_test.rb"
          f.contents <<-RB
            class Class1Test
              def test_name
              end
            end
          RB
        end
      end

      launch("test_name", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test /src/test/class_1_test.rb --name='/test_name/'", shell_mock.recall_exec

      launch("n", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test /src/test/class_1_test.rb --name='/n/'", shell_mock.recall_exec
    end

    def test__by_example__multiple_methods__same_file
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/class_1_test.rb"
          f.contents <<-RB
            class Class1Test
              def test_name_1
              end

              def test_name_2
              end
            end
          RB
        end
      end

      launch("name_", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test /src/test/class_1_test.rb --name='/name_/'", shell_mock.recall_exec
    end

    def test__by_example__multiple_methods__regex_issue
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/class_1_test.rb"
          f.mtime Time.new(2014, 01, 01, 00, 00, 00)
          f.contents <<-RB
            def test_name_1
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/test/class_2_test.rb"
          f.mtime Time.new(2015, 01, 01, 00, 00, 00)
          f.contents <<-RB
            def test_somename
          RB
        end
      end

      launch("test_name", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test /src/test/class_1_test.rb --name='/test_name/'", shell_mock.recall_exec

      skip
      # not seeing a good solution here...
      # we cannot tell whether the _ is part of the test_ or not.
      # might need to do two passes: first with user input, then
      # filter down to those that match test_...would that work?
      launch("_name", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test /src/test/class_1_test.rb --name='/test_name/'", shell_mock.recall_exec
    end

    def test__by_example__multiple_methods__different_files
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/class_1_test.rb"
          f.mtime Time.new(2014, 01, 01, 00, 00, 00)
          f.contents <<-RB
            def test_name_1
            def test_name_2
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/test/class_2_test.rb"
          f.mtime Time.new(2015, 01, 01, 00, 00, 00)
          f.contents <<-RB
            def test_name_1
            def test_name_2
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/test/class_3_test.rb"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
          f.contents <<-RB
            def test_name_2
          RB
        end
      end

      launch("name_1", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test /src/test/class_2_test.rb --name='/name_1/'", shell_mock.recall_exec

      launch("name_2", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test /src/test/class_2_test.rb --name='/name_2/'", shell_mock.recall_exec

      launch("name_1 --all", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test -r bundler/setup -e \"ARGV.push('--name=/name_1/')\" -r /src/test/class_1_test.rb -r /src/test/class_2_test.rb", shell_mock.recall_exec

      launch("name_2 --all", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test -r bundler/setup -e \"ARGV.push('--name=/name_2/')\" -r /src/test/class_1_test.rb -r /src/test/class_2_test.rb -r /src/test/class_3_test.rb", shell_mock.recall_exec

      launch("name_1|name_2 --all", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test -r bundler/setup -e \"ARGV.push('--name=/name_1|name_2/')\" -r /src/test/class_1_test.rb -r /src/test/class_2_test.rb -r /src/test/class_3_test.rb", shell_mock.recall_exec
    end

    def test__by_filename
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1_test.rb"
          f.contents ""
        end
      end

      launch("file_1", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' /src/test/file_1_test.rb", shell_mock.recall_exec

      launch("file_1_test.rb", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' /src/test/file_1_test.rb", shell_mock.recall_exec

      launch("/file_1", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' /src/test/file_1_test.rb", shell_mock.recall_exec

      launch(".rb", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' /src/test/file_1_test.rb", shell_mock.recall_exec

      launch("/src/test/file_1", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' /src/test/file_1_test.rb", shell_mock.recall_exec

      launch("src/test/file_1", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' /src/test/file_1_test.rb", shell_mock.recall_exec

      launch("st/file_1", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' /src/test/file_1_test.rb", shell_mock.recall_exec
    end

    def test__by_filename__multiple_files_found
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1_test.rb"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
        end

        searcher.mock_file do |f|
          f.path "/src/test/file_2_test.rb"
          f.mtime Time.new(2015, 01, 01, 00, 00, 00)
        end

        searcher.mock_file do |f|
          f.path "/src/test/file_3_test.rb"
          f.mtime Time.new(2014, 01, 01, 00, 00, 00)
        end

        searcher.mock_file do |f|
          f.path "/src/test/other_test.rb"
        end
      end

      launch("file_1", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' /src/test/file_1_test.rb", shell_mock.recall_exec

      launch("file", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' /src/test/file_2_test.rb", shell_mock.recall_exec

      launch("file --all", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' /src/test/file_1_test.rb /src/test/file_2_test.rb /src/test/file_3_test.rb", shell_mock.recall_exec
    end

    def test__by_filename__preferred_over_regex_and_test_name_matches
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/class_1_test.rb"
          f.contents <<-RB
            def test_name
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/test/name_test.rb"
        end

        searcher.mock_file do |f|
          f.path "/src/test/other_test.rb"
          f.contents <<-RB
            regex will match name_test
          RB
        end
      end

      launch("name_test", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' /src/test/name_test.rb", shell_mock.recall_exec
    end

    def test__by_multiple_filenames__multiple_files_found
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1_test.rb"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
          f.contents ""
        end

        searcher.mock_file do |f|
          f.path "/src/test/file_2_test.rb"
          f.mtime Time.new(2015, 01, 01, 00, 00, 00)
          f.contents ""
        end

        searcher.mock_file do |f|
          f.path "/src/test/file_3_test.rb"
          f.mtime Time.new(2014, 01, 01, 00, 00, 00)
          f.contents ""
        end

        searcher.mock_file do |f|
          f.path "/src/test/other_test.rb"
          f.contents ""
        end
      end

      launch("file_1 file_2", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' /src/test/file_1_test.rb /src/test/file_2_test.rb", shell_mock.recall_exec

      launch("file_1 file", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' /src/test/file_1_test.rb /src/test/file_2_test.rb /src/test/file_3_test.rb", shell_mock.recall_exec

      # If multiple queries are submitted but not all of them match,
      # then what should we do? For now, we assume that it's only
      # considered a match if each query term matches at least one
      # or more files.
      launch("file_1 gibberish", searcher: searcher)
      assert_equal nil, shell_mock.recall_exec
    end

    def test_uses_spring__if_spring_binstub_found
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/class_1_test.rb"
          f.contents <<-RB
            def test_name
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/bin/spring"
          f.contents ""
        end
      end


      launch("class_1_test.rb", env: {}, searcher: searcher)
      assert_equal "cd /src && bundle exec spring testunit /src/test/class_1_test.rb", shell_mock.recall_exec

      launch("class_1_test.rb", env: {"DISABLE_SPRING" => "1"}, searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' /src/test/class_1_test.rb", shell_mock.recall_exec
    end

    def test__by_regex__one_match
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1_test.rb"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
          f.contents <<-RB
            regex match 1
            regex match 2
            regex match 3
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/test/file_2_test.rb"
          f.mtime Time.new(2015, 01, 01, 00, 00, 00)
          f.contents <<-RB
            regex match 1
            regex match 2
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/test/file_3_test.rb"
          f.mtime Time.new(2014, 01, 01, 00, 00, 00)
          f.contents <<-RB
            regex match 1
            regex match 3
          RB
        end
      end

      launch("regex match 1", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' /src/test/file_2_test.rb", shell_mock.recall_exec

      launch("regex match 3", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' /src/test/file_3_test.rb", shell_mock.recall_exec

      launch("regex match", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' /src/test/file_2_test.rb", shell_mock.recall_exec

      launch("regex match --all", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' /src/test/file_1_test.rb /src/test/file_2_test.rb /src/test/file_3_test.rb", shell_mock.recall_exec
    end

    def test__by_example__preferred_over_regex
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1_test.rb"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
          f.contents <<-RB
            def test_regex_match
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/test/file_2_test.rb"
          f.mtime Time.new(2015, 01, 01, 00, 00, 00)
          f.contents <<-RB
            regex_match
          RB
        end
      end

      launch("regex_match", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test /src/test/file_1_test.rb --name='/regex_match/'", shell_mock.recall_exec
    end

    def test__multiple_queries__generic_regex__prefers_to_keep_spaces
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1_test.rb"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
          f.contents <<-RB
            this matches
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/test/file_2_test.rb"
          f.mtime Time.new(2015, 01, 01, 00, 00, 00)
          f.contents <<-RB
            this
            matches
          RB
        end

        launch("this matches", searcher: searcher)
        assert_equal "cd /src && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' /src/test/file_1_test.rb", shell_mock.recall_exec

        launch("this matches --all", searcher: searcher)
        assert_equal "cd /src && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' /src/test/file_1_test.rb", shell_mock.recall_exec

        launch("matches this --all", searcher: searcher)
        assert_equal "cd /src && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' /src/test/file_1_test.rb /src/test/file_2_test.rb", shell_mock.recall_exec
      end
    end

    def test__multiple_queries__splits_spaces_for_test_names
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1_test.rb"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
          f.contents <<-RB
            def test_this
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/test/file_2_test.rb"
          f.mtime Time.new(2015, 01, 01, 00, 00, 00)
          f.contents <<-RB
            def test_matches
          RB
        end

        launch("this matches", searcher: searcher)
        assert_equal "cd /src && bundle exec ruby -I test -r bundler/setup -e \"ARGV.push('--name=/this|matches/')\" -r /src/test/file_1_test.rb -r /src/test/file_2_test.rb", shell_mock.recall_exec

        launch("this matches --all", searcher: searcher)
        assert_equal "cd /src && bundle exec ruby -I test -r bundler/setup -e \"ARGV.push('--name=/this|matches/')\" -r /src/test/file_1_test.rb -r /src/test/file_2_test.rb", shell_mock.recall_exec

        launch("this    matches", searcher: searcher)
        assert_equal "cd /src && bundle exec ruby -I test -r bundler/setup -e \"ARGV.push('--name=/this|matches/')\" -r /src/test/file_1_test.rb -r /src/test/file_2_test.rb", shell_mock.recall_exec
      end
    end

    def test__helper_methods_are_considered_regexes
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1_test.rb"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
          f.contents <<-RB
            def helper_method
          RB
        end
      end

      launch("helper_method", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' /src/test/file_1_test.rb", shell_mock.recall_exec
    end

    def test__by_example__handles_regex_for_example_name
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1_test.rb"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
          f.contents <<-RB
            def test_name_1
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/test/file_2_test.rb"
          f.mtime Time.new(2015, 01, 01, 00, 00, 00)
          f.contents <<-RB
            def test_name_2
          RB
        end
      end

      launch("test_name_1$", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test /src/test/file_1_test.rb --name='/test_name_1$/'", shell_mock.recall_exec

      launch("test_name_2|test_name_1", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test /src/test/file_2_test.rb --name='/test_name_2|test_name_1/'", shell_mock.recall_exec

      launch('test_name_\d', searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test /src/test/file_2_test.rb --name='/test_name_\\d/'", shell_mock.recall_exec

      launch('test_name_\d --all', searcher: searcher)
      assert_equal %{cd /src && bundle exec ruby -I test -r bundler/setup -e "ARGV.push('--name=/test_name_\\d/')" -r /src/test/file_1_test.rb -r /src/test/file_2_test.rb}, shell_mock.recall_exec
    end

    def test__not_found
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1_test.rb"
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
          f.path "/src/test/file_1_test.rb"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
          f.contents <<-RB
            def test_name_1
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/test/file_2_test.rb"
          f.mtime Time.new(2015, 01, 01, 00, 00, 00)
          f.contents <<-RB
            def test_name_2
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/inline/gem/test/file_1_test.rb"
          f.mtime Time.new(2014, 01, 01, 00, 00, 00)
          f.contents <<-RB
            def test_name_1
          RB
        end
      end

      launch("test_name_1", searcher: searcher)
      assert_equal "cd /src/inline/gem && bundle exec ruby -I test /src/inline/gem/test/file_1_test.rb --name='/test_name_1/'", shell_mock.recall_exec

      launch("test_name_1 --all", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test -r bundler/setup -e \"ARGV.push('--name=/test_name_1/')\" -r /src/test/file_1_test.rb; cd -;\n\ncd /src/inline/gem && bundle exec ruby -I test -r bundler/setup -e \"ARGV.push('--name=/test_name_1/')\" -r /src/inline/gem/test/file_1_test.rb", shell_mock.recall_exec

      launch("file --all", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' /src/test/file_1_test.rb /src/test/file_2_test.rb; cd -;\n\ncd /src/inline/gem && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' /src/inline/gem/test/file_1_test.rb", shell_mock.recall_exec

      launch("file_1", searcher: searcher)
      assert_equal "cd /src/inline/gem && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' /src/inline/gem/test/file_1_test.rb", shell_mock.recall_exec

      launch("file_1 --all", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' /src/test/file_1_test.rb; cd -;\n\ncd /src/inline/gem && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' /src/inline/gem/test/file_1_test.rb", shell_mock.recall_exec
    end

    def test__specified_example_name__simple
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1_test.rb"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
          f.contents <<-RB
            def test_name_1
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/inline/gem/test/file_2_test.rb"
          f.mtime Time.new(2015, 01, 01, 00, 00, 00)
          f.contents <<-RB
            def test_name_2
          RB
        end
      end

      launch("file_1 --name test_name_1", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test /src/test/file_1_test.rb --name='/test_name_1/'", shell_mock.recall_exec

      launch("file_2 --name test_name_2", searcher: searcher)
      assert_equal "cd /src/inline/gem && bundle exec ruby -I test /src/inline/gem/test/file_2_test.rb --name='/test_name_2/'", shell_mock.recall_exec
    end

    def test__specified_example_name__multiple_files_same_name
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1_test.rb"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
          f.contents <<-RB
            def test_name_1
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/inline/gem/test/file_1_test.rb"
          f.mtime Time.new(2015, 01, 01, 00, 00, 00)
          f.contents <<-RB
            def test_name_1
          RB
        end
      end

      launch("file_1 --name test_name_1", searcher: searcher)
      assert_equal "cd /src/inline/gem && bundle exec ruby -I test /src/inline/gem/test/file_1_test.rb --name='/test_name_1/'", shell_mock.recall_exec
    end

    def test__by_line_number
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1_test.rb"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
          f.contents <<-RB
            class File1Test
              def test_name_1
                things
              end

              def test_name_2
                things
              end
            end
          RB
        end
      end

      launch("file_1_test.rb:1", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' /src/test/file_1_test.rb", shell_mock.recall_exec

      launch("file_1_test.rb:2", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test /src/test/file_1_test.rb --name='/test_name_1/'", shell_mock.recall_exec

      launch("file_1_test.rb:3", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test /src/test/file_1_test.rb --name='/test_name_1/'", shell_mock.recall_exec

      launch("file_1_test.rb:4", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test /src/test/file_1_test.rb --name='/test_name_1/'", shell_mock.recall_exec

      launch("file_1_test.rb:5", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test /src/test/file_1_test.rb --name='/test_name_1/'", shell_mock.recall_exec

      launch("file_1_test.rb:6", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test /src/test/file_1_test.rb --name='/test_name_2/'", shell_mock.recall_exec

      launch("file_1_test.rb:7", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test /src/test/file_1_test.rb --name='/test_name_2/'", shell_mock.recall_exec

      launch("file_1_test.rb:8", searcher: searcher)
      assert_equal "cd /src && bundle exec ruby -I test /src/test/file_1_test.rb --name='/test_name_2/'", shell_mock.recall_exec
    end

    def test__by_line_number__multiple_files
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1_test.rb"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
          f.contents <<-RB
            class File1Test
            def test_name_1
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/inline/gem/test/file_1_test.rb"
          f.mtime Time.new(2014, 01, 01, 00, 00, 00)
          f.contents <<-RB
            class File1Test
            def test_name_1
          RB
        end
      end

      launch("file_1_test.rb:1", searcher: searcher)
      assert shell_mock.recall(:warn).first.first.to_s.match(/Open an issue/)
    end

    def test__rerun
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1_test.rb"
          f.mtime Time.new(2014, 01, 01, 00, 00, 00)
        end

        searcher.mock_file do |f|
          f.path "/src/test/file_2_test.rb"
          f.mtime Time.new(2015, 01, 01, 00, 00, 00)
        end
      end

      history_shell = Shell::HistoryRunner.new(shell: shell_mock, history_path: File.expand_path(File.join(__dir__, '../../tmp/test_history.log')))

      launch("file_1_test.rb", searcher: searcher, shell: history_shell)
      assert_equal "cd /src && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' /src/test/file_1_test.rb", history_shell.recall_exec

      launch("--rerun", searcher: searcher, shell: history_shell )
      assert_equal "cd /src && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' /src/test/file_1_test.rb", history_shell.recall_exec
    end
  end
end

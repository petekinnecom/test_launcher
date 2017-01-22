require "test_helper"
require "test_helpers/integration_helper"

module TestLauncher
  class RspecIntegrationTest < TestCase
    include IntegrationHelper

    def launch(query, env: {}, searcher:)
      query += " --framework rspec"
      shell_mock.reset
      CLI.launch(query.split(" "), env, shell: shell_mock, searcher: searcher)
    end

    def test__by_example__single_example
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/spec/class_1_spec.rb"
          f.contents <<-RB
            it "does a thing" do
          RB
        end
      end

      launch("thing", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/class_1_spec.rb --example thing", shell_mock.recall_exec

      launch("does a thing", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/class_1_spec.rb --example does\\ a\\ thing", shell_mock.recall_exec

      launch("n", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/class_1_spec.rb --example n", shell_mock.recall_exec
    end

    def test__by_example__multiple_examples__same_file
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/spec/class_1_spec.rb"
          f.contents <<-RB
              it "name_1" do
              it "name_2" do
            end
          RB
        end
      end

      launch("name_", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/class_1_spec.rb --example name_", shell_mock.recall_exec
    end

    def test__by_example__multiple_methods__different_files
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/spec/class_1_spec.rb"
          f.mtime Time.new(2014, 01, 01, 00, 00, 00)
          f.contents <<-RB
            it "test_name_1" do
            it "test_name_2" do
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/spec/class_2_spec.rb"
          f.mtime Time.new(2015, 01, 01, 00, 00, 00)
          f.contents <<-RB
            it "test_name_1" do
            it "test_name_2" do
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/spec/class_3_spec.rb"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
          f.contents <<-RB
            it "test_name_2" do
          RB
        end
      end

      launch("name_1", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/class_2_spec.rb --example name_1", shell_mock.recall_exec

      launch("name_2", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/class_2_spec.rb --example name_2", shell_mock.recall_exec

      launch("name_1 --all", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/class_1_spec.rb /src/spec/class_2_spec.rb", shell_mock.recall_exec

      launch("name_2 --all", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/class_1_spec.rb /src/spec/class_2_spec.rb /src/spec/class_3_spec.rb", shell_mock.recall_exec
    end

    def test__by_filename
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/spec/file_1_spec.rb"
          f.contents ""
        end
      end

      launch("file_1", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/file_1_spec.rb", shell_mock.recall_exec

      launch("file_1_spec.rb", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/file_1_spec.rb", shell_mock.recall_exec

      launch("/file_1", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/file_1_spec.rb", shell_mock.recall_exec

      launch(".rb", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/file_1_spec.rb", shell_mock.recall_exec

      launch("/src/spec/file_1", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/file_1_spec.rb", shell_mock.recall_exec

      launch("src/spec/file_1", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/file_1_spec.rb", shell_mock.recall_exec

      launch("ec/file_1", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/file_1_spec.rb", shell_mock.recall_exec
    end

    def test__by_filename__multiple_files_found
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/spec/file_1_spec.rb"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
        end

        searcher.mock_file do |f|
          f.path "/src/spec/file_2_spec.rb"
          f.mtime Time.new(2015, 01, 01, 00, 00, 00)
        end

        searcher.mock_file do |f|
          f.path "/src/spec/file_3_spec.rb"
          f.mtime Time.new(2014, 01, 01, 00, 00, 00)
        end

        searcher.mock_file do |f|
          f.path "/src/spec/other_spec.rb"
        end
      end

      launch("file_1", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/file_1_spec.rb", shell_mock.recall_exec

      launch("file", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/file_2_spec.rb", shell_mock.recall_exec

      launch("file --all", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/file_1_spec.rb /src/spec/file_2_spec.rb /src/spec/file_3_spec.rb", shell_mock.recall_exec
    end

    def test__by_filename__preferred_over_regex_and_test_name_matches
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/spec/class_1_spec.rb"
          f.contents <<-RB
            it "name_spec" do
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/spec/name_spec.rb"
        end

        searcher.mock_file do |f|
          f.path "/src/spec/other_spec.rb"
          f.contents <<-RB
            regex will match name_spec
          RB
        end
      end

      launch("name_spec", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/name_spec.rb", shell_mock.recall_exec
    end

    def test__by_multiple_filenames__multiple_files_found
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/spec/file_1_spec.rb"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
          f.contents ""
        end

        searcher.mock_file do |f|
          f.path "/src/spec/file_2_spec.rb"
          f.mtime Time.new(2015, 01, 01, 00, 00, 00)
          f.contents ""
        end

        searcher.mock_file do |f|
          f.path "/src/spec/file_3_spec.rb"
          f.mtime Time.new(2014, 01, 01, 00, 00, 00)
          f.contents ""
        end

        searcher.mock_file do |f|
          f.path "/src/spec/other_tspecrb"
          f.contents ""
        end
      end

      launch("file_1 file_2", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/file_1_spec.rb /src/spec/file_2_spec.rb", shell_mock.recall_exec

      launch("file_1 file", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/file_1_spec.rb /src/spec/file_2_spec.rb /src/spec/file_3_spec.rb", shell_mock.recall_exec

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
          f.path "/src/spec/file_1_spec.rb"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
          f.contents <<-RB
            regex match 1
            regex match 2
            regex match 3
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/spec/file_2_spec.rb"
          f.mtime Time.new(2015, 01, 01, 00, 00, 00)
          f.contents <<-RB
            regex match 1
            regex match 2
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/spec/file_3_spec.rb"
          f.mtime Time.new(2014, 01, 01, 00, 00, 00)
          f.contents <<-RB
            regex match 1
            regex match 3
          RB
        end
      end

      launch("regex match 1", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/file_2_spec.rb", shell_mock.recall_exec

      launch("regex match 3", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/file_3_spec.rb", shell_mock.recall_exec

      launch("regex match", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/file_2_spec.rb", shell_mock.recall_exec

      launch("regex match --all", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/file_1_spec.rb /src/spec/file_2_spec.rb /src/spec/file_3_spec.rb", shell_mock.recall_exec
    end

    def test__by_example__preferred_over_regex
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/spec/file_1_spec.rb"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
          f.contents <<-RB
            it "regex_match" do
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/spec/file_2_spec.rb"
          f.mtime Time.new(2015, 01, 01, 00, 00, 00)
          f.contents <<-RB
            regex_match
          RB
        end
      end

      launch("regex_match", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/file_1_spec.rb --example regex_match", shell_mock.recall_exec
    end

    def test__context_blocks_are_treated_as_examples
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/spec/file_1_spec.rb"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
          f.contents <<-RB
            describe "test_1" do
            context "test_2" do
            RSpec.describe "test_3" do
          RB
        end
      end

      launch("test_1", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/file_1_spec.rb --example test_1", shell_mock.recall_exec

      launch("test_2", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/file_1_spec.rb --example test_2", shell_mock.recall_exec

      launch("test_3", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/file_1_spec.rb --example test_3", shell_mock.recall_exec
    end

    def test__by_example__handles_regex_for_example_name
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/spec/file_1_spec.rb"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
          f.contents <<-RB
            it "test_name_1" do
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/spec/file_2_spec.rb"
          f.mtime Time.new(2015, 01, 01, 00, 00, 00)
          f.contents <<-RB
            it "test_name_2" do
          RB
        end
      end

      launch("test_name_1x?", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/file_1_spec.rb --example test_name_1x\\?", shell_mock.recall_exec

      launch("test_name_2|test_name_1", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/file_2_spec.rb --example test_name_2\\|test_name_1", shell_mock.recall_exec

      launch('test_name_\d', searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/file_2_spec.rb --example test_name_\\\\d", shell_mock.recall_exec

      launch('test_name_\d --all', searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/file_1_spec.rb /src/spec/file_2_spec.rb", shell_mock.recall_exec
    end

    def test__not_found
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/spec/file_1_spec.rb"
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
          f.path "/src/spec/file_1_spec.rb"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
          f.contents <<-RB
            it 'test_name_1' do
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/spec/file_2_spec.rb"
          f.mtime Time.new(2015, 01, 01, 00, 00, 00)
          f.contents <<-RB
            it 'test_name_2' do
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/inline/gem/spec/file_1_spec.rb"
          f.mtime Time.new(2014, 01, 01, 00, 00, 00)
          f.contents <<-RB
            it 'test_name_1' do
          RB
        end
      end

      launch("test_name_1", searcher: searcher)
      assert_equal "cd /src/inline/gem && bundle exec rspec /src/inline/gem/spec/file_1_spec.rb --example test_name_1", shell_mock.recall_exec

      launch("test_name_1 --all", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/file_1_spec.rb; cd -;\n\ncd /src/inline/gem && bundle exec rspec /src/inline/gem/spec/file_1_spec.rb", shell_mock.recall_exec

      launch("file --all", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/file_1_spec.rb /src/spec/file_2_spec.rb; cd -;\n\ncd /src/inline/gem && bundle exec rspec /src/inline/gem/spec/file_1_spec.rb", shell_mock.recall_exec

      launch("file_1", searcher: searcher)
      assert_equal "cd /src/inline/gem && bundle exec rspec /src/inline/gem/spec/file_1_spec.rb", shell_mock.recall_exec

      launch("file_1 --all", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/file_1_spec.rb; cd -;\n\ncd /src/inline/gem && bundle exec rspec /src/inline/gem/spec/file_1_spec.rb", shell_mock.recall_exec
    end

    def test__specified_example_name__simple
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/spec/file_1_spec.rb"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
          f.contents <<-RB
            it "test_name_1" do
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/inline/gem/spec/file_2_spec.rb"
          f.mtime Time.new(2015, 01, 01, 00, 00, 00)
          f.contents <<-RB
            it "test_name_2" do
          RB
        end
      end

      launch("file_1 --name test_name_1", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/file_1_spec.rb --example test_name_1", shell_mock.recall_exec

      launch("file_2 --name test_name_2", searcher: searcher)
      assert_equal "cd /src/inline/gem && bundle exec rspec /src/inline/gem/spec/file_2_spec.rb --example test_name_2", shell_mock.recall_exec

      launch("file_1 --example test_name_1", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/file_1_spec.rb --example test_name_1", shell_mock.recall_exec
    end

    def test__specified_example_name__multiple_files_same_name
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/spec/file_1_spec.rb"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
          f.contents <<-RB
            it "test_name_1" do
          RB
        end

        searcher.mock_file do |f|
          f.path "/src/inline/gem/spec/file_1_spec.rb"
          f.mtime Time.new(2015, 01, 01, 00, 00, 00)
          f.contents <<-RB
            it "test_name_1" do
          RB
        end
      end

      launch("file_1_spec.rb --name test_name_1", searcher: searcher)
      assert_equal "cd /src/inline/gem && bundle exec rspec /src/inline/gem/spec/file_1_spec.rb --example test_name_1", shell_mock.recall_exec

      launch("file_1 --name test_name_1", searcher: searcher)
      assert_equal "cd /src/inline/gem && bundle exec rspec /src/inline/gem/spec/file_1_spec.rb --example test_name_1", shell_mock.recall_exec
    end

    def test__by_line_number__just_passes_through_to_rspec
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/spec/file_1_spec.rb"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
          f.contents ""
        end
      end

      launch("file_1_spec.rb:1", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/file_1_spec.rb:1", shell_mock.recall_exec

      launch("/src/spec/file_1_spec.rb:1", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/file_1_spec.rb:1", shell_mock.recall_exec

      launch("file_1_spec.rb:273", searcher: searcher)
      assert_equal "cd /src && bundle exec rspec /src/spec/file_1_spec.rb:273", shell_mock.recall_exec
    end

    def test__by_line_number__multiple_files
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/spec/file_1_spec.rb"
          f.mtime Time.new(2013, 01, 01, 00, 00, 00)
          f.contents ""
        end

        searcher.mock_file do |f|
          f.path "/src/inline/gem/spec/file_1_spec.rb"
          f.mtime Time.new(2014, 01, 01, 00, 00, 00)
          f.contents ""
        end
      end

      launch("file_1_spec.rb:1", searcher: searcher)
      assert_equal "cd /src/inline/gem && bundle exec rspec /src/inline/gem/spec/file_1_spec.rb:1", shell_mock.recall_exec
    end
  end
end

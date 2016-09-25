require "test_helper"

module TestLauncher
  class MinitestIntegrationTest < TestCase
    def test__single_method
      TestLauncher.launch("file_name_1__method_name_1", framework: "minitest")
      assert_equal "cd #{system_path("test/test_launcher/fixtures/minitest")} && bundle exec ruby -I test test/class_1_test.rb --name=/file_name_1__method_name_1/", Shell::Runner.recall_exec
    end

    def test__multiple_methods__same_file
      TestLauncher.launch("file_name_1", framework: "minitest")
      assert_equal "cd #{system_path("test/test_launcher/fixtures/minitest")} && bundle exec ruby -I test test/class_1_test.rb --name=/file_name_1/", Shell::Runner.recall_exec
    end

    def test__multiple_methods__different_files
      TestLauncher.launch("multiple_files__same_method", framework: "minitest")
      assert_equal "cd #{system_path("test/test_launcher/fixtures/minitest")} && bundle exec ruby -I test test/class_2_test.rb --name=/multiple_files__same_method/", Shell::Runner.recall_exec
    end

    def test__single_file
      TestLauncher.launch("class_1_test", framework: "minitest")
      assert_equal "cd #{system_path("test/test_launcher/fixtures/minitest")} && bundle exec ruby -I test -e 'ARGV.each {|f| require(File.join(Dir.pwd, f))}' test/class_1_test.rb", Shell::Runner.recall_exec
    end

    def test__uses_spring
      TestLauncher.launch("different_roo""t_test", framework: "minitest") # don't trigger the find in *this* file
      assert_equal "cd #{system_path("test/test_launcher/fixtures/minitest/test/different_root")} && spring testunit test/different_root_test.rb", Shell::Runner.recall_exec
    end

    def test__multiple_files
      TestLauncher.launch("Root1""Dum""myTest""Class", framework: "minitest") # don't trigger the find in *this* file
      assert_equal "cd #{system_path("test/test_launcher/fixtures/minitest")} && bundle exec ruby -I test -e 'ARGV.each {|f| require(File.join(Dir.pwd, f))}' test/class_2_test.rb", Shell::Runner.recall_exec
    end

    def test__multiple_files__all
      TestLauncher.launch("Root1""DummyTest""Class", run_all: true, framework: "minitest") # don't trigger the find in *this* file
      assert_equal "cd #{system_path("test/test_launcher/fixtures/minitest")} && bundle exec ruby -I test -e 'ARGV.each {|f| require(File.join(Dir.pwd, f))}' test/class_1_test.rb test/class_2_test.rb", Shell::Runner.recall_exec
    end

    def test__multiple_files__different_roots__all
      TestLauncher.launch("DummyTest""Class", run_all: true, framework: "minitest") # don't trigger the find in *this* file
      expected = "cd #{system_path("test/test_launcher/fixtures/minitest")} && bundle exec ruby -I test -e 'ARGV.each {|f| require(File.join(Dir.pwd, f))}' test/class_1_test.rb test/class_2_test.rb; cd -;\n\ncd #{system_path("test/test_launcher/fixtures/minitest/test/different_root")} && spring testunit test/different_root_test.rb"
      assert_equal expected, Shell::Runner.recall_exec
    end

    def test__regex
      TestLauncher.launch("Root1""DummyTest""Class1""Test", framework: "minitest") # don't trigger the find in *this* file
      assert_equal "cd #{system_path("test/test_launcher/fixtures/minitest")} && bundle exec ruby -I test -e 'ARGV.each {|f| require(File.join(Dir.pwd, f))}' test/class_1_test.rb", Shell::Runner.recall_exec
    end

    def test__regex__does_not_test_helper__methods
      TestLauncher.launch("helper_meth""od", framework: "minitest") # don't trigger the find in *this* file
      assert_equal "cd #{system_path("test/test_launcher/fixtures/minitest")} && bundle exec ruby -I test -e 'ARGV.each {|f| require(File.join(Dir.pwd, f))}' test/class_1_test.rb", Shell::Runner.recall_exec
    end

    def test__not_found
      TestLauncher.launch("not_found""thing", framework: "minitest")
      assert_equal nil, Shell::Runner.recall_exec
    end

    private

    def system_path(relative_dir)
      File.join(Dir.pwd, relative_dir)
    end
  end
end

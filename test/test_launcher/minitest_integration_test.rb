require "test_helper"
require "test_helpers/integration_helper"

module TestLauncher
  class MinitestIntegrationTest < TestCase
    include IntegrationHelper

    def test__single_method
      launch("file_name_1__method_name_1", framework: "minitest")
      assert_equal "cd #{system_path("test/test_launcher/fixtures/minitest")} && bundle exec ruby -I test #{system_path("test/test_launcher/fixtures/minitest/test/class_1_test.rb")} --name=/file_name_1__method_name_1/", Shell::Runner.recall_exec
    end

    def test__multiple_methods__same_file
      launch("file_name_1", framework: "minitest")
      assert_equal "cd #{system_path("test/test_launcher/fixtures/minitest")} && bundle exec ruby -I test #{system_path("test/test_launcher/fixtures/minitest/test/class_1_test.rb")} --name=/file_name_1/", Shell::Runner.recall_exec
    end

    def test__multiple_methods__different_files
      launch("multiple_files__same_method", framework: "minitest")
      assert_equal "cd #{system_path("test/test_launcher/fixtures/minitest")} && bundle exec ruby -I test #{system_path("test/test_launcher/fixtures/minitest/test/class_2_test.rb")} --name=/multiple_files__same_method/", Shell::Runner.recall_exec
    end

    def test__single_file
      launch("class_1_test", framework: "minitest")
      assert_equal "cd #{system_path("test/test_launcher/fixtures/minitest")} && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' #{system_path("test/test_launcher/fixtures/minitest/test/class_1_test.rb")}", Shell::Runner.recall_exec
    end

    def test__uses_spring
      launch("different_roo""t_test", framework: "minitest") # don't trigger the find in *this* file
      assert_equal "cd #{system_path("test/test_launcher/fixtures/minitest/test/different_root")} && bundle exec spring testunit #{system_path("test/test_launcher/fixtures/minitest/test/different_root/test/different_root_test.rb")}", Shell::Runner.recall_exec
    end

    def test__multiple_files__found
      launch("Root1""Dum""myTest""Class", framework: "minitest") # don't trigger the find in *this* file
      assert_equal "cd #{system_path("test/test_launcher/fixtures/minitest")} && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' #{system_path("test/test_launcher/fixtures/minitest/test/class_2_test.rb")}", Shell::Runner.recall_exec
    end

    def test__multiple_files__found__all
      launch("Root1""DummyTest""Class", run_all: true, framework: "minitest") # don't trigger the find in *this* file
      assert_equal "cd #{system_path("test/test_launcher/fixtures/minitest")} && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' #{system_path("test/test_launcher/fixtures/minitest/test/class_1_test.rb")} #{system_path("test/test_launcher/fixtures/minitest/test/class_2_test.rb")}", Shell::Runner.recall_exec
    end

    def test__multiple_file_paths
      launch("class_1_tes""t.rb class_2_test.rb", framework: "minitest") # don't trigger the find in *this* file
      assert_equal "cd #{system_path("test/test_launcher/fixtures/minitest")} && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' #{system_path("test/test_launcher/fixtures/minitest/test/class_1_test.rb")} #{system_path("test/test_launcher/fixtures/minitest/test/class_2_test.rb")}", Shell::Runner.recall_exec
    end

    def test__multiple_files__different_roots__all
      launch("DummyTest""Class", run_all: true, framework: "minitest") # don't trigger the find in *this* file
      expected = "cd #{system_path("test/test_launcher/fixtures/minitest")} && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' #{system_path("test/test_launcher/fixtures/minitest/test/class_1_test.rb")} #{system_path("test/test_launcher/fixtures/minitest/test/class_2_test.rb")}; cd -;\n\ncd #{system_path("test/test_launcher/fixtures/minitest/test/different_root")} && bundle exec spring testunit #{system_path("test/test_launcher/fixtures/minitest/test/different_root/test/different_root_test.rb")}"
      assert_equal expected, Shell::Runner.recall_exec
    end

    def test__regex
      launch("Root1""DummyTest""Class1""Test", framework: "minitest") # don't trigger the find in *this* file
      assert_equal "cd #{system_path("test/test_launcher/fixtures/minitest")} && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' #{system_path("test/test_launcher/fixtures/minitest/test/class_1_test.rb")}", Shell::Runner.recall_exec
    end

    def test__regex__does_not_test_helper__methods
      launch("helper_meth""od", framework: "minitest") # don't trigger the find in *this* file
      assert_equal "cd #{system_path("test/test_launcher/fixtures/minitest")} && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' #{system_path("test/test_launcher/fixtures/minitest/test/class_1_test.rb")}", Shell::Runner.recall_exec
    end

    def test__not_found
      launch("not_found""thing", framework: "minitest")
      assert_equal nil, Shell::Runner.recall_exec
    end

  end
end

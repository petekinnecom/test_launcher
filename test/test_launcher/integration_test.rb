require "test_helper"

module TestLauncher
  class IntegrationTest < TestCase

    class Shell::Runner
      def exec(cmd)
        raise "execed twice" if defined?(@exec)
        @@exec = cmd
      end

      def notify(*)
        # silence logs during test
      end

      def self.recall_exec
        @@exec.to_s
      end
    end

    def test__single_method
      TestLauncher.launch("file_name_1__method_name_1")
      assert_equal "cd ./test/test_launcher/fixtures/minitest && ruby -I test test/class_1_test.rb --name=/test__file_name_1__method_name_1/", Shell::Runner.recall_exec
    end

    def test__multiple_methods__same_file
      skip "existing bug"
      TestLauncher.launch("file_name_1")
      assert_equal "cd ./test/test_launcher/fixtures/minitest && ruby -I test test/class_1_test.rb --name=/file_name_1/", Shell::Runner.recall_exec
    end

    def test__multiple_methods__different_files
      TestLauncher.launch("multiple_files__same_method")
      assert_equal "cd ./test/test_launcher/fixtures/minitest && ruby -I test test/class_2_test.rb --name=/test__multiple_files__same_method/", Shell::Runner.recall_exec
    end

    def test__single_file
      TestLauncher.launch("class_1_test")
      assert_equal "cd ./test/test_launcher/fixtures/minitest && ruby -I test test/class_1_test.rb", Shell::Runner.recall_exec
    end

    def test__multiple_files
      TestLauncher.launch("Root1""DummyTest""Class") # don't trigger the find in *this* file
      assert_equal "cd ./test/test_launcher/fixtures/minitest && ruby -I test test/class_2_test.rb", Shell::Runner.recall_exec
    end

    def test__multiple_files__all
      TestLauncher.launch("Root1""DummyTest""Class", run_all: true) # don't trigger the find in *this* file
      assert_equal "cd ./test/test_launcher/fixtures/minitest && ruby -I test -e 'ARGV.each { |file| require(Dir.pwd + \"/\" + file) }' test/class_1_test.rb test/class_2_test.rb", Shell::Runner.recall_exec
    end

    def test__multiple_files__different_roots__all
      TestLauncher.launch("DummyTest""Class", run_all: true) # don't trigger the find in *this* file
      expected = "cd ./test/test_launcher/fixtures/minitest && ruby -I test -e 'ARGV.each { |file| require(Dir.pwd + \"/\" + file) }' test/class_1_test.rb test/class_2_test.rb; cd -;\n\ncd ./test/test_launcher/fixtures/minitest/test/different_root && ruby -I test -e 'ARGV.each { |file| require(Dir.pwd + \"/\" + file) }' test/different_root_test.rb"
      assert_equal expected, Shell::Runner.recall_exec
    end

    def test__regex
      TestLauncher.launch("Root1""DummyTest""Class1""Test") # don't trigger the find in *this* file
      assert_equal "cd ./test/test_launcher/fixtures/minitest && ruby -I test test/class_1_test.rb", Shell::Runner.recall_exec
    end
  end
end

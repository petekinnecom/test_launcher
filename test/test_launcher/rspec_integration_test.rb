require "test_helper"

module TestLauncher
  class RspecIntegrationTest < TestCase

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
      TestLauncher.launch("file_name_1 example_name_""1", framework: "rspec")
      assert_equal "cd ./test/test_launcher/fixtures/rspec && rspec spec/class_1_spec.rb --example file_name_1\\ example_name_1\\ \\'\\\\\\\"\\ ", Shell::Runner.recall_exec
    end

    def test__single_context
      TestLauncher.launch("file_name_1 con""text_1", framework: "rspec")
      assert_equal "cd ./test/test_launcher/fixtures/rspec && rspec spec/class_1_spec.rb --example file_name_1\\ context_1", Shell::Runner.recall_exec
    end

    def test__single_describe
      TestLauncher.launch("Root1DummyTes""tClass1", framework: "rspec")
      assert_equal "cd ./test/test_launcher/fixtures/rspec && rspec spec/class_1_spec.rb --example Root1DummyTes""tClass1", Shell::Runner.recall_exec
    end

    def test__multiple_methods__same_file
      skip "existing bug"
      TestLauncher.launch("file_name_1", framework: "rspec")
      assert_equal "cd ./test/test_launcher/fixtures/rspec && rspec spec/class_1_spec.rb --example file_name_1", Shell::Runner.recall_exec
    end

    def test__multiple_methods__different_files
      TestLauncher.launch("multiple_files same_example", framework: "rspec")
      assert_equal "cd ./test/test_launcher/fixtures/rspec && rspec spec/class_2_spec.rb --example multiple_files\\ same_example", Shell::Runner.recall_exec
    end

    def test__single_file
      TestLauncher.launch("class_1_spec", framework: "rspec")
      assert_equal "cd ./test/test_launcher/fixtures/rspec && rspec spec/class_1_spec.rb", Shell::Runner.recall_exec
    end

    def test__multiple_files
      TestLauncher.launch("Root1", framework: "rspec") # don't trigger the find in *this* file
      assert_equal "cd ./test/test_launcher/fixtures/rspec && rspec spec/class_2_spec.rb --example Root1""Du""mmyTestClass2", Shell::Runner.recall_exec
    end

    def test__multiple_files__all
      TestLauncher.launch("Root1""DummyTest""Class", run_all: true, framework: "rspec") # don't trigger the find in *this* file
      assert_equal "cd ./test/test_launcher/fixtures/rspec && rspec spec/class_1_spec.rb spec/class_2_spec.rb", Shell::Runner.recall_exec
    end

    def test__multiple_files__different_roots__all
      TestLauncher.launch("DummyTest""Class", run_all: true, framework: "rspec") # don't trigger the find in *this* file
      expected = "cd ./test/test_launcher/fixtures/rspec && rspec spec/class_1_spec.rb spec/class_2_spec.rb; cd -;\n\ncd ./test/test_launcher/fixtures/rspec/spec/different_root && rspec spec/different_root_spec.rb"
      assert_equal expected, Shell::Runner.recall_exec
    end

    def test__regex
      TestLauncher.launch("a_test_that_u""ses", framework: "rspec") # don't trigger the find in *this* file
      assert_equal "cd ./test/test_launcher/fixtures/rspec && rspec spec/class_2_spec.rb", Shell::Runner.recall_exec
    end
  end
end

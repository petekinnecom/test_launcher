require "test_helper"
require "test_launcher/request"

module TestLauncher
  class RspecIntegrationTest < TestCase
    def test__single_method
      launch("file_name_1 example_name_""1")
      assert_equal "cd #{system_path("test/test_launcher/fixtures/rspec")} && rspec #{system_path("test/test_launcher/fixtures/rspec/spec/class_1_spec.rb")} --example file_name_1\\ example_name_1", Shell::Runner.recall_exec
    end

    def test__single_context
      launch("file_name_1 con""text_1")
      assert_equal "cd #{system_path("test/test_launcher/fixtures/rspec")} && rspec #{system_path("test/test_launcher/fixtures/rspec/spec/class_1_spec.rb")} --example file_name_1\\ context_1", Shell::Runner.recall_exec
    end

    def test__single_describe
      launch("Root1DummyTes""tClass1")
      assert_equal "cd #{system_path("test/test_launcher/fixtures/rspec")} && rspec #{system_path("test/test_launcher/fixtures/rspec/spec/class_1_spec.rb")} --example Root1DummyTes""tClass1", Shell::Runner.recall_exec
    end

    def test__multiple_methods__same_file
      launch("file_name_1")
      assert_equal "cd #{system_path("test/test_launcher/fixtures/rspec")} && rspec #{system_path("test/test_launcher/fixtures/rspec/spec/class_1_spec.rb")} --example file_name_1", Shell::Runner.recall_exec
    end

    def test__multiple_methods__different_files
      launch("multiple_files same_example")
      assert_equal "cd #{system_path("test/test_launcher/fixtures/rspec")} && rspec #{system_path("test/test_launcher/fixtures/rspec/spec/class_2_spec.rb")} --example multiple_files\\ same_example", Shell::Runner.recall_exec
    end

    def test__single_file
      launch("class_1_spec")
      assert_equal "cd #{system_path("test/test_launcher/fixtures/rspec")} && rspec #{system_path("test/test_launcher/fixtures/rspec/spec/class_1_spec.rb")}", Shell::Runner.recall_exec
    end

    def test__multiple_files__found
      launch("Root1") # don't trigger the find in *this* file
      assert_equal "cd #{system_path("test/test_launcher/fixtures/rspec")} && rspec #{system_path("test/test_launcher/fixtures/rspec/spec/class_2_spec.rb")} --example Roo""t1", Shell::Runner.recall_exec
    end

    def test__multiple_files__found__all
      launch("Root1""DummyTest""Class", run_all: true) # don't trigger the find in *this* file
      assert_equal "cd #{system_path("test/test_launcher/fixtures/rspec")} && rspec #{system_path("test/test_launcher/fixtures/rspec/spec/class_1_spec.rb")} #{system_path("test/test_launcher/fixtures/rspec/spec/class_2_spec.rb")}", Shell::Runner.recall_exec
    end

    def test__multiple_file_paths
      launch("class_1_spec.rb class_2_spec.rb") # don't trigger the find in *this* file
      assert_equal "cd #{system_path("test/test_launcher/fixtures/rspec")} && rspec #{system_path("test/test_launcher/fixtures/rspec/spec/class_1_spec.rb")} #{system_path("test/test_launcher/fixtures/rspec/spec/class_2_spec.rb")}", Shell::Runner.recall_exec
    end

    def test__multiple_files__different_roots__all
      launch("DummyTest""Class", run_all: true) # don't trigger the find in *this* file
      expected = "cd #{system_path("test/test_launcher/fixtures/rspec")} && rspec #{system_path("test/test_launcher/fixtures/rspec/spec/class_1_spec.rb")} #{system_path("test/test_launcher/fixtures/rspec/spec/class_2_spec.rb")}; cd -;\n\ncd #{system_path("test/test_launcher/fixtures/rspec/spec/different_root")} && rspec #{system_path("test/test_launcher/fixtures/rspec/spec/different_root/spec/different_root_spec.rb")}"
      assert_equal expected, Shell::Runner.recall_exec
    end

    def test__regex
      launch("a_test_that_u""ses") # don't trigger the find in *this* file
      assert_equal "cd #{system_path("test/test_launcher/fixtures/rspec")} && rspec #{system_path("test/test_launcher/fixtures/rspec/spec/class_2_spec.rb")}", Shell::Runner.recall_exec
    end

    def test__not_found
      launch("not_found""thing")
      assert_equal nil, Shell::Runner.recall_exec
    end

    private

    def system_path(relative_dir)
      File.join(Dir.pwd, relative_dir)
    end

    def launch(query, run_all: false)
      request = Request.new(
        query: query,
        run_all: run_all,
        framework: "rspec"
      )

      TestLauncher.launch(request)
    end
  end
end

require "test_helper"
require "test_helpers/integration_helper"

module TestLauncher
  class GenericIntegrationTest < TestCase
    include IntegrationHelper

    def launch(query, env: {}, searcher:, shell: shell_mock)
      query = query.split(" ") if query.is_a?(String)
      query += ["--framework", "generic"]
      shell.reset
      CLI.launch(query, env, shell: shell, searcher: searcher)
    end

    def test__by_filename
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1.rb"
          f.contents ""
        end
      end

      launch("file_1", searcher: searcher)
      assert_equal "ruby /src/test/file_1.rb", shell_mock.recall_exec
    end

    def test__not_filename
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1.rb"
          f.contents "runme"
        end
      end

      launch("runme", searcher: searcher)
      assert_equal nil, shell_mock.recall_exec

      launch("file:1", searcher: searcher)
      assert_equal nil, shell_mock.recall_exec

      launch("/src/test/file_1.rb:1", searcher: searcher)
      assert_equal nil, shell_mock.recall_exec
    end

    def test__configured_wrapper
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1.rb"
          f.contents ""
        end
      end

      Dir.stubs(:pwd).returns('/src')

      query = [
        "file_1",
        "--root-override",
        "/home/code"
      ]
      launch(query, searcher: searcher)
      assert_equal "ruby /home/code/test/file_1.rb", shell_mock.recall_exec
    end

    def test__configured_wrapper__trailing_slash
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1.rb"
          f.contents ""
        end
      end

      Dir.stubs(:pwd).returns('/src')

      query = [
        "file_1",
        "--root-override",
        "/home/code/"
      ]
      launch(query, searcher: searcher)
      assert_equal "ruby /home/code/test/file_1.rb", shell_mock.recall_exec
    end
  end
end

require "test_helper"
require "test_helpers/integration_helper"

module TestLauncher
  class GenericIntegrationTest < TestCase
    include IntegrationHelper

    def launch(query, env: {}, searcher:, shell: shell_mock, &block)
      query += " --framework generic "
      shell.reset
      CLI.launch(query.split(" "), env, shell: shell, searcher: searcher, &block)
    end

    def recall_exec(searcher, shell: shell_mock)
      shell
        .recall_exec
        &.gsub(searcher.dir, "")
    end

    def test__by_filename
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1.rb"
          f.contents ""
        end
      end

      launch("file_1", searcher: searcher)
      assert_equal "ruby /src/test/file_1.rb", recall_exec(searcher)
    end

    def test__not_filename
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1.rb"
          f.contents "runme"
        end
      end

      launch("runme", searcher: searcher)
      assert_equal nil, recall_exec(searcher)

      launch("file:1", searcher: searcher)
      assert_equal nil, recall_exec(searcher)

      launch("/src/test/file_1.rb:1", searcher: searcher)
      assert_equal nil, recall_exec(searcher)
    end

    def test__cli_yields_block
      # TODO: don't test this here
      searcher = MemorySearcher.new do |searcher|
        searcher.mock_file do |f|
          f.path "/src/test/file_1.rb"
          f.contents "runme"
        end
      end
      @yielded = false
      launch("/src/test/file_1.rb", searcher: searcher) do |command|
        @yielded = true
        assert_equal "ruby /src/test/file_1.rb", command.gsub(searcher.dir, "")
        "new_command"
      end
      assert @yielded
      assert_equal "new_command", recall_exec(searcher)
    end
  end
end

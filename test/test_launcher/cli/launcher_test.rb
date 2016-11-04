require "test_helper"
require "test_launcher/base_error"
require "test_launcher/cli/request"

module TestLauncher
  module CLI
    class LauncherTest < TestCase

      class DummyFramework1
        def self.commandify(request:, shell:, searcher:)
          if ["dummy_framework_1", "both"].include? request.query
            "dummy_framework_1_command"
          elsif request.query == "error"
            raise BaseError.new("error_message")
          end
        end
      end

      class DummyFramework2
        def self.commandify(request:, shell:, searcher:)
          if ["dummy_framework_2", "both"].include? request.query
            "dummy_framework_2_command"
          end
        end
      end

      class DummyRequest < CLI::Request
        def frameworks
          [DummyFramework1, DummyFramework2]
        end
      end

      def test_locates__from_one_framework
        Launcher.launch(
          shell: dummy_shell,
          searcher: Object.new,
          request: DummyRequest.new(query: "dummy_framework_1")
        )

        assert_equal [["dummy_framework_1_command"]], dummy_shell.recall(:exec)
      end

      def test_locates__from_second_framework
        Launcher.launch(
          shell: dummy_shell,
          searcher: Object.new,
          request: DummyRequest.new(query: "dummy_framework_2")
        )

        assert_equal [["dummy_framework_2_command"]], dummy_shell.recall(:exec)
      end


      def test_locates__assumes_frameworks_are_in_priority_order
        Launcher.launch(
          shell: dummy_shell,
          searcher: Object.new,
          request: DummyRequest.new(query: "both")
        )

        assert_equal [["dummy_framework_1_command"]], dummy_shell.recall(:exec)
      end

      def test_locates__warns_when_nothing_found
        Launcher.launch(
          shell: dummy_shell,
          searcher: Object.new,
          request: DummyRequest.new(query: "not found")
        )

        assert_equal [], dummy_shell.recall(:exec)
        assert_equal [["No tests found."]], dummy_shell.recall(:warn)
      end

      def test_locates__warns_error_message
        Launcher.launch(
          shell: dummy_shell,
          searcher: Object.new,
          request: DummyRequest.new(query: "error")
        )

        assert_equal [], dummy_shell.recall(:exec)
        assert_equal 1, dummy_shell.recall(:warn).length

        warning = dummy_shell.recall(:warn).first.first
        assert_equal BaseError, warning.class
        assert_equal "error_message", warning.message
      end
    end
  end
end

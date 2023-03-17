require "test_helper"
require "test_launcher/rubymine/launcher"
require "test_launcher/rubymine/request"
require "test_launcher/rubymine/parser"

module TestLauncher
  class RubymineTest < TestCase
    def test_launch__run__file
      glob_pattern = "/Users/username/some_app/engines/some_engine/test/does_something_test.rb"
      Dir.expects(:glob).with(glob_pattern).returns([glob_pattern])
      args = "/Users/username/some_app/bin/spring testunit #{glob_pattern}"
      expected_command = "cd /Users/username/some_app/engines/some_engine && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' /Users/username/some_app/engines/some_engine/test/does_something_test.rb"

      assert_executes expected_command, args
    end

    def test_launch__run__folder
      glob_pattern = "/Users/username/some_app/engines/some_engine/test/**/*.rb"
      glob_results = %w[/Users/username/some_app/engines/some_engine/test/some_high_level_test.rb /Users/username/some_app/engines/some_engine/test/some_module/some_module_test]
      Dir.expects(:glob).with(glob_pattern).returns(glob_results)
      args = "/Users/username/some_app/bin/spring testunit #{glob_pattern}"
      expected_command = "cd /Users/username/some_app/engines/some_engine && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' #{glob_results.join(' ')}"

      assert_executes expected_command, args
    end

    def test_launch__run__example__spring
      args = "/Users/username/some_app/bin/spring testunit /Users/username/some_app/engines/some_engine/test/does_something_test.rb --name=some_test_name"
      expected_command = "cd /Users/username/some_app/engines/some_engine && bundle exec ruby -I test /Users/username/some_app/engines/some_engine/test/does_something_test.rb --name=some_test_name"

      assert_executes expected_command, args
    end

    def test_launch__run__example__spring__with_regex
      args = "/Users/username/some_app/bin/spring testunit /Users/username/some_app/engines/some_engine/test/does_something_test.rb --name /some_test_name/"
      expected_command = "cd /Users/username/some_app/engines/some_engine && bundle exec ruby -I test /Users/username/some_app/engines/some_engine/test/does_something_test.rb --name=some_test_name"

      assert_executes expected_command, args
    end

    def test_launch__run__example__no_spring
      args = "/Users/username/some_app/engines/some_engine/test/does_something_test.rb --name=some_test_name"
      expected_command = "cd /Users/username/some_app/engines/some_engine && bundle exec ruby -I test /Users/username/some_app/engines/some_engine/test/does_something_test.rb --name=some_test_name"

      assert_executes expected_command, args
    end

    def test_launch__run__example__no_spring__regex
      args = "/Users/username/some_app/engines/some_engine/test/does_something_test.rb --name /some_test_name/"
      expected_command = "cd /Users/username/some_app/engines/some_engine && bundle exec ruby -I test /Users/username/some_app/engines/some_engine/test/does_something_test.rb --name=some_test_name"

      assert_executes expected_command, args
    end

    def test_launch__run__example__no_spring__no_disable_spring
      args = "/Users/username/some_app/engines/some_engine/test/does_something_test.rb --name=some_test_name"
      expected_command = "cd /Users/username/some_app/engines/some_engine && bundle exec ruby -I test /Users/username/some_app/engines/some_engine/test/does_something_test.rb --name=some_test_name"

      assert_executes expected_command, args, disable_spring: false
    end

    def test_launch__debug__example
      args = "/Users/username/.rvm/gems/ruby-2.2.3/gems/ruby-debug-ide-0.6.1.beta2/bin/rdebug-ide --disable-int-handler --evaluation-timeout 10 --rubymine-protocol-extensions --port 58930 --host 0.0.0.0 --dispatcher-port 58931 -- /Users/username/some_app/bin/spring testunit /Users/username/some_app/engines/some_engine/test/does_something_test.rb --name=some_test_name"
      expected_command = "cd /Users/username/some_app/engines/some_engine && bundle exec ruby -I test /Users/username/.rvm/gems/ruby-2.2.3/gems/ruby-debug-ide-0.6.1.beta2/bin/rdebug-ide --disable-int-handler --evaluation-timeout 10 --rubymine-protocol-extensions --port 58930 --host 0.0.0.0 --dispatcher-port 58931 -- /Users/username/some_app/bin/spring testunit /Users/username/some_app/engines/some_engine/test/does_something_test.rb --name=some_test_name"

      assert_executes(expected_command, args)
    end

    def test_launch__debug__file
      glob_pattern = "/Users/username/some_app/engines/some_engine/test/does_something_test.rb"
      Dir.expects(:glob).with(glob_pattern).returns([glob_pattern])
      args = "/Users/username/.rvm/gems/ruby-2.2.3/gems/ruby-debug-ide-0.6.1.beta2/bin/rdebug-ide --disable-int-handler --evaluation-timeout 10 --rubymine-protocol-extensions --port 58930 --host 0.0.0.0 --dispatcher-port 58931 -- /Users/username/some_app/bin/spring testunit #{glob_pattern}"
      expected_command = "cd /Users/username/some_app/engines/some_engine && bundle exec ruby -I test /Users/username/.rvm/gems/ruby-2.2.3/gems/ruby-debug-ide-0.6.1.beta2/bin/rdebug-ide --disable-int-handler --evaluation-timeout 10 --rubymine-protocol-extensions --port 58930 --host 0.0.0.0 --dispatcher-port 58931 -- /Users/username/some_app/bin/spring testunit /Users/username/some_app/engines/some_engine/test/does_something_test.rb"

      assert_executes(expected_command, args)
    end

    def test_launcher__run__2020_style
      args = "/usr/local/bin/bash -c \"env RBENV_VERSION=2.6.3 /usr/local/Cellar/rbenv/1.1.2/libexec/rbenv exec ruby -r test_launcher/rubymine -Itest /Users/username/some_app/engines/some_engine/test/does_something_test.rb --name '/^some_test_name$/'\""
      expected_command = "cd /Users/username/some_app/engines/some_engine && bundle exec ruby -I test /Users/username/some_app/engines/some_engine/test/does_something_test.rb --name=some_test_name"

      assert_executes(expected_command, args)
    end

    def test_launcher__debug__2020_style
      args = "/bin/bash -c \"/Users/username/.rvm/bin/rvm ruby-2.6.3 do /Users/username/.rvm/rubies/ruby-2.6.3/bin/bundle exec /Users/username/.rvm/rubies/ruby-2.6.3/bin/ruby -r test_launcher/rubymine -Itest /Users/username/.rvm/gems/ruby-2.6.3/gems/ruby-debug-ide-0.8.0.beta23/bin/rdebug-ide --key-value --step-over-in-blocks --disable-int-handler --evaluation-timeout 10 --evaluation-control --time-limit 100 --memory-limit 0 --rubymine-protocol-extensions --port 51357 --host 0.0.0.0 --dispatcher-port 51358 -- /Users/username/some_app/engines/some_engine/test/does_something_test.rb --name '/^some_test_name$/'\""
      expected_command = "cd /Users/username/some_app/engines/some_engine && #{args}"

      assert_executes(expected_command, args)
    end

    def test_launcher__run__2020_2_3_style__test_method
      ENV["INTELLIJ_IDEA_RUN_CONF_TEST_FILE_PATH"] = "/path/to/app/test/my_test.rb"

      args = "/usr/local/bin/bash -c \"env RBENV_VERSION=2.6.3 /usr/local/Cellar/rbenv/1.1.2/libexec/rbenv exec ruby -Itest /Applications/RubyMine.app/Contents/plugins/ruby/rb/testing/runner/minitest_runner.rb --name '/^test_method$/'\""

      Rubymine::Parser.launch(shell: dummy_shell, argv: args.split(" "))

      expected_command = "cd /path/to/app && bundle exec ruby -I test /path/to/app/test/my_test.rb --name=test_method"
      assert_equal [[expected_command]], dummy_shell.recall(:exec)
    end

    def test_launcher__run__2020_2_3_style__test_file
      glob_pattern = "/path/to/app/test/my_test.rb"
      Dir.expects(:glob).with(glob_pattern).returns([glob_pattern])
      ENV["INTELLIJ_IDEA_RUN_CONF_TEST_FILE_PATH"] = glob_pattern

      args = "/usr/local/bin/bash -c \"env RBENV_VERSION=2.6.3 /usr/local/Cellar/rbenv/1.1.2/libexec/rbenv exec ruby -Itest /Applications/RubyMine.app/Contents/plugins/ruby/rb/testing/runner/minitest_runner.rb\""

      Rubymine::Parser.launch(shell: dummy_shell, argv: args.split(" "))

      expected_command = "cd /path/to/app && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' #{glob_pattern}"
      assert_equal [[expected_command]], dummy_shell.recall(:exec)
    end

    private

    def assert_executes(expected_command, args, disable_spring: true)
      request = Rubymine::Request.new(disable_spring: disable_spring)

      launcher = Rubymine::Launcher.new(
        args: args.split(" "),
        shell: dummy_shell,
        request: request
      )

      launcher.launch
      assert_equal 1, dummy_shell.recall(:exec).size
      assert_equal [[expected_command]], dummy_shell.recall(:exec)
    end
  end
end

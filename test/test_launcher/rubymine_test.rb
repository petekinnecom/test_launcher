require "test_helper"
require "test_launcher/rubymine/launcher"
require "test_launcher/rubymine/request"

module TestLauncher
  class RubymineTest < TestCase
    def test_launch__run__file
      args = "/Users/username/some_app/bin/spring testunit /Users/username/some_app/engines/some_engine/test/does_something_test.rb"
      expected_command = "cd /Users/username/some_app/engines/some_engine && bundle exec ruby -I test -e 'ARGV.each {|f| require(f)}' /Users/username/some_app/engines/some_engine/test/does_something_test.rb"

      assert_executes expected_command, args
    end

    def test_launch__run__example__spring
      args = "/Users/username/some_app/bin/spring testunit /Users/username/some_app/engines/some_engine/test/does_something_test.rb --name=some_test_name"
      expected_command = "cd /Users/username/some_app/engines/some_engine && bundle exec ruby -I test /Users/username/some_app/engines/some_engine/test/does_something_test.rb --name='some_test_name'"

      assert_executes expected_command, args
    end

    def test_launch__run__example__no_spring
      args = "/Users/username/some_app/engines/some_engine/test/does_something_test.rb --name=some_test_name"
      expected_command = "cd /Users/username/some_app/engines/some_engine && bundle exec ruby -I test /Users/username/some_app/engines/some_engine/test/does_something_test.rb --name='some_test_name'"

      assert_executes expected_command, args
    end

    def test_launch__run__example__no_spring__no_disable_spring
      args = "/Users/username/some_app/engines/some_engine/test/does_something_test.rb --name=some_test_name"
      expected_command = "cd /Users/username/some_app/engines/some_engine && bundle exec ruby -I test /Users/username/some_app/engines/some_engine/test/does_something_test.rb --name='some_test_name'"

      assert_executes expected_command, args, disable_spring: false
    end

    def test_launch__debug__example
      args = "/Users/username/.rvm/gems/ruby-2.2.3/gems/ruby-debug-ide-0.6.1.beta2/bin/rdebug-ide --disable-int-handler --evaluation-timeout 10 --rubymine-protocol-extensions --port 58930 --host 0.0.0.0 --dispatcher-port 58931 -- /Users/username/some_app/bin/spring testunit /Users/username/some_app/engines/some_engine/test/does_something_test.rb --name=some_test_name"
      expected_command = "cd /Users/username/some_app/engines/some_engine && ruby -I test /Users/username/.rvm/gems/ruby-2.2.3/gems/ruby-debug-ide-0.6.1.beta2/bin/rdebug-ide --disable-int-handler --evaluation-timeout 10 --rubymine-protocol-extensions --port 58930 --host 0.0.0.0 --dispatcher-port 58931 -- /Users/username/some_app/bin/spring testunit /Users/username/some_app/engines/some_engine/test/does_something_test.rb --name=some_test_name"

      assert_executes(expected_command, args)
    end

    def test_launch__debug__file
      args = "/Users/username/.rvm/gems/ruby-2.2.3/gems/ruby-debug-ide-0.6.1.beta2/bin/rdebug-ide --disable-int-handler --evaluation-timeout 10 --rubymine-protocol-extensions --port 58930 --host 0.0.0.0 --dispatcher-port 58931 -- /Users/username/some_app/bin/spring testunit /Users/username/some_app/engines/some_engine/test/does_something_test.rb"
      expected_command = "cd /Users/username/some_app/engines/some_engine && ruby -I test /Users/username/.rvm/gems/ruby-2.2.3/gems/ruby-debug-ide-0.6.1.beta2/bin/rdebug-ide --disable-int-handler --evaluation-timeout 10 --rubymine-protocol-extensions --port 58930 --host 0.0.0.0 --dispatcher-port 58931 -- /Users/username/some_app/bin/spring testunit /Users/username/some_app/engines/some_engine/test/does_something_test.rb"

      assert_executes(expected_command, args)
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

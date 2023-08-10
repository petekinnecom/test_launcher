$LOAD_PATH.unshift(File.join(File.split(File.dirname(__FILE__))[0], 'lib'))
require "minitest/autorun"
require "mocha/minitest"
require "pry"

require "test_launcher"
require "test_launcher/shell/runner"

class TestLauncher::Shell::Runner
  def exec(cmd)
    raise "execed twice" if defined?(@exec)
    @@exec = cmd
  end

  def notify(*)
    # silence logs during test
  end

  def warn(*)
    # silence logs during test
  end

  def self.recall_exec
    return unless @@exec
    @@exec.to_s
  end

  def self.reset
    @@exec = nil
  end
end

class TestCase < Minitest::Test

  def setup
    TestLauncher::Shell::Runner.reset
  end

  class DummyShell

    def method_missing(method, *args)
      instance_variable_set(:"@#{method}", [args])

      self.class.send(:define_method, method) do |*a|
        if ! instance_variable_get(:"@#{method}")
          instance_variable_set(:"@#{method}", [a])
        end
      end
    end

    def recall(method)
      instance_variable_get(:"@#{method}") || []
    end
  end

  private

  def system_path(relative_dir)
    File.join(Dir.pwd, relative_dir)
  end

  def dummy_shell
    @dummy_shell ||= DummyShell.new
  end

  def stub_app_root(dir)
    TestLauncher::Frameworks::Implementation::TestCase
      .any_instance
      .stubs(:app_root)
      .returns(dir)
  end
end

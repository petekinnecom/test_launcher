$LOAD_PATH.unshift(File.join(File.split(File.dirname(__FILE__))[0], 'lib'))
require "minitest/autorun"
require "mocha/mini_test"
require "pry"

require "test_launcher"

class TestCase < Minitest::Test
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
      instance_variable_get(:"@#{method}")
    end
  end

  private

  def dummy_shell
    @dummy_shell ||= DummyShell.new
  end
end

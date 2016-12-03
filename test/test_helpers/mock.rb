class Mock
  UnmockedMethodError = Class.new(StandardError)
  MockingUnimplementedMethodError = Class.new(StandardError)

  def self.impl(method_name)
    define_method method_name do |*args|
      record_call(method_name, args)
      yield(*args) if block_given?
    end
  end

  def self.mocks(klass)
    define_method(:mocked_klass) do
      klass
    end
  end

  def impl(method_name)
    define_singleton_method method_name do |*args|
      record_call(method_name, args)
      yield(*args) if block_given?
    end
  end

  def initialize(*args)
    @attrs = args.pop || {}
    @klass = args.first if args.any?
    @calls = {}
    yield(self) if block_given?
    raise "Mocked class not specified" unless mocked_klass
  end

  def recall(method_name)
    @calls[method_name] || []
  end

  private

  def method_missing(method_name, *args)
    record_call(method_name, args)

    if @attrs.key?(method_name)
      @attrs[method_name]
    else
      raise UnmockedMethodError, "#{method_name} is not mocked"
    end
  end

  def record_call(method_name, args)
    if !mocked_klass.method_defined?(method_name)
      raise MockingUnimplementedMethodError, "#{mocked_klass} does not implement #{method_name}"
    end
    (@calls[method_name] ||= []) << args
  end

  def mocked_klass
    @klass
  end
end

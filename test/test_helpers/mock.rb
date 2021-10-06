class Mock
  UnmockedMethodError = Class.new(StandardError)
  MockingUnimplementedMethodError = Class.new(StandardError)

  def self.impl(method_name)
    define_method method_name do |*a, **o|
      recorded_args = o.empty? ? a : a + [o]

      record_call(method_name, recorded_args)
      yield(*a, **o) if block_given?
    end
  end

  def self.mocks(klass)
    define_method(:mocked_klass) do
      klass
    end
  end

  def impl(method_name)
    define_singleton_method method_name do |*a, **o|
      recorded_args = o.empty? ? a : a + [o]

      record_call(method_name, recorded_args)
      yield(*a, **o) if block_given?
    end
  end

  def initialize(*args, **o)
    @attrs = o.merge(to_hash: nil)
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
    return if [:to_hash].include?(method_name)

    if !mocked_klass.method_defined?(method_name)
      raise MockingUnimplementedMethodError, "#{mocked_klass} does not implement #{method_name}"
    end
    (@calls[method_name] ||= []) << args
  end

  def mocked_klass
    @klass
  end
end

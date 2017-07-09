module TestLauncher
  module CLI
    class Options < Struct.new(
      :search_string,
      :frameworks,
      :rerun,
      :run_all,
      :disable_spring,
      :example_name,
      :shell,
      :searcher,
      :wrap,
      :root_override
    )
      def initialize(**args)
        raise ArgumentError.new("These keys are allowed and required: #{members}") unless args.keys.sort == members.sort
        args.each { |k, v| self[k] = v }
      end
    end
  end
end

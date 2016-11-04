module TestLauncher
  module Utils
    class Kstruct < Struct

      def initialize(**args)
        raise ArgumentError.new("required keys: #{members}") unless args.keys.sort == members.sort

        args.each { |k, v| self[k] = v }
      end
    end
  end
end

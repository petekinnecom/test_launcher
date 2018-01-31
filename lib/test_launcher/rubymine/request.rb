module TestLauncher
  module Rubymine
    class Request
      def initialize(disable_spring:)
        @disable_spring = disable_spring
      end

      def disable_spring?
        @disable_spring
      end

      def force_spring?
        false
      end
    end
  end
end

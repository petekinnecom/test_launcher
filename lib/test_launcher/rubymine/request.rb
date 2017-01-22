module TestLauncher
  module Rubymine
    class Request
      def initialize(disable_spring:)
        @disable_spring = disable_spring
      end

      def disable_spring?
        @disable_spring
      end
    end
  end
end

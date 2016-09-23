require "pathname"

module TestLauncher
  module Utils
    module Path

      def self.split(filename)
        Pathname.new(filename).each_filename.to_a
      end
    end
  end
end

require "pathname"

module TestRun
  module Utils
    module Path

      def self.split(filename)
        self.prepend_pwd(Pathname.new(filename).each_filename.to_a)
      end

      def self.path_for(filename)
        self.split(File.split(file)[0])
      end

      def self.join(*array)
        File.join(*array)
      end

      def self.prepend_pwd(dirs)
        if dirs[0] == "."
          dirs
        else
          ["."] + dirs
        end
      end

      def self.relative_join(array)
        join(prepend_pwd(array))
      end
    end
  end
end

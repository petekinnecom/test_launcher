require "test_launcher/base_error"
require "shellwords"

module TestLauncher
  module Search
    class Ag
      NotInRepoError = Class.new(BaseError)
      class Interface
        attr_reader :shell

        def initialize(shell)
          @shell = shell
        end

        def ls_files(pattern)
          shell.run("ag -g '.*#{pattern_to_regex(pattern)}.*'")
        end

        def grep(regex, file_pattern)
          shell.run("ag #{Shellwords.escape(regex)} --file-search-regex '#{pattern_to_regex(file_pattern)}'")
        end

        def root_path
          @result ||= (ENV['TEST_LAUNCHER__DIR'] || Dir.pwd)
        end

        def pattern_to_regex(pattern)
          pattern.gsub("*", ".*")
        end
      end

      attr_reader :interface

      def initialize(shell, interface=Interface.new(shell))
        @interface = interface
        Dir.chdir(root_path) # MOVE ME!
      end

      def find_files(pattern)
        relative_pattern = strip_system_path(pattern)
        interface.ls_files(relative_pattern).map {|f| system_path(f)}
      end

      def grep(regex, file_pattern: '*')
        results = interface.grep(regex, strip_system_path(file_pattern))
        results.map do |result|
          interpret_grep_result(result)
        end
      end


      private

      def interpret_grep_result(grep_result)
        splits = grep_result.split(/:/)
        file = splits.shift.strip
        line_number = splits.shift.strip.to_i
        # we rejoin on ':' because our
        # code may have colons inside of it.
        #
        # example:
        # path/to/file:126: run_method(a: A, b: B)
        #
        # so shift the first one out, then
        # rejoin the rest
        line = splits.join(':').strip

        # TODO: Oh goodness, why is this not a class
        {
          :file => system_path(file),
          :line_number => line_number.to_i,
          :line => line,
        }
      end

      def system_path(file)
        File.join(root_path, file)
      end

      def strip_system_path(file)
        file.sub(/^#{root_path}\//, '')
      end

      def root_path
        @root_path ||= interface.root_path
      end

      def shell
        @shell
      end
    end
  end
end

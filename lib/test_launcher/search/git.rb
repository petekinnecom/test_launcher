module TestLauncher
  module Search
    class Git
      class Interface
        attr_reader :shell

        def initialize(shell)
          @shell = shell
        end

        def ls_files(pattern)
          shell.run("git ls-files '*#{pattern}*'")
        end

        def grep(regex, file_pattern)
          shell.run("git grep --untracked --extended-regexp '#{regex}' -- '#{file_pattern}'")
        end

        def root_path
          shell.run("git rev-parse --show-toplevel").first.tap do
            if $? != 0
              shell.warn "test_launcher must be used in a git repository"
              exit
            end
          end
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
        results = interface.grep(regex, file_pattern)
        results.map do |result|
          interpret_grep_result(result)
        end
      end

      private

      def interpret_grep_result(grep_result)
        splits = grep_result.split(/:/)
        file = splits.shift.strip
        # we rejoin on ':' because our
        # code may have colons inside of it.
        #
        # example:
        # path/to/file: run_method(a: A, b: B)
        #
        # so shift the first one out, then
        # rejoin the rest
        line = splits.join(':').strip

        {
          :file => system_path(file),
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

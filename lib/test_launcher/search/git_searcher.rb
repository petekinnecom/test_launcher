module TestLauncher
  module Searchers
    class GitSearcher < Struct.new(:shell)

      def find_files(pattern)
        shell.run("git ls-files '*#{pattern}*'").map {|f| system_path(f)}
      end

      def grep(regex, file_pattern: '*')
        results = shell.run("git grep --untracked --extended-regexp '#{regex}' -- '#{file_pattern}'")
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

      def root_path
        @root_path ||= %x[ git rev-parse --show-toplevel ].chomp
      end
    end
  end
end

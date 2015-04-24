require "test_run/utils/path"

module TestRun
  module Tests
    module Minitest
      module Wrappers
        class SingleRoot

          attr_reader :files, :shell

          def initialize(files, shell)
            @shell = shell
            @files = files.map {|f| f.is_a?(SingleFile) ? f : SingleFile.new(f)}
          end

          def should_run?
            true
          end

          def to_command
            %{cd #{app_root} && ruby -I test -e 'ARGV.each { |file| require(Dir.pwd + "/" + file) }' #{files.map(&:relative_test_path).join(" ")}}
          end

          def app_root
            files.first.app_root
          end

        end
      end
    end
  end
end

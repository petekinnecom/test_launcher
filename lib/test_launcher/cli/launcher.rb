require "test_launcher/base_error"
require "test_launcher/frameworks"

module TestLauncher
  module CLI
    module Launcher
      def self.launch(shell:, searcher:, request:)

        command = nil
        request.frameworks.each { |framework|
          command = framework.commandify(
            request: request,
            shell: shell,
            searcher: searcher
          )

          break if command
        }

        if command
          shell.exec command
        else
          shell.warn "No tests found."
        end
      rescue BaseError => e
        shell.warn(e)
      end
    end
  end
end

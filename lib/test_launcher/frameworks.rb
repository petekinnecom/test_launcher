require "test_launcher/frameworks/minitest"


module TestLauncher
  module Frameworks
    def self.command_for(input, shell:, searcher:, run_all:)
      Minitest.command_for(input, shell: shell, searcher: searcher, run_all: run_all)
    end
  end
end

require 'test_launcher/search/ag'
require 'test_launcher/search/git'

module TestLauncher
  module Search
    def self.searcher(shell)
        if ENV.key?('TEST_LAUNCHER__AG')
          Search::Ag.new(shell)
        else
          Search::Git.new(shell)
        end
    end
  end
end

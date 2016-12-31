require 'test_launcher/search/ag'
require 'test_launcher/search/git'

module TestLauncher
  module Search
    def self.searcher(shell)
      `which ag`
      implementation =
        if $?.success?
          Search::Ag
        else
          Search::Git
        end

      implementation.new(shell)
    end
  end
end

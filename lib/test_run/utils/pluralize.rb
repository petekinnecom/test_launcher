module TestRun
  module Utils
    module Pluralize
      def pluralize(count, singular)
        phrase = "#{count} #{singular}"
        if count == 1
          phrase
        else
          "#{phrase}s"
        end
      end
    end
  end
end

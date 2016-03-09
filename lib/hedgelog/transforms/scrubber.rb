require 'hedgelog/transforms/scrub_replacement'

class Hedgelog
  module Transforms
    class Scrubber
      def initialize(replacements = nil)
        @replacements = replacements || [
          ScrubReplacement.new('password', '**********')
        ]
      end

      def transform(data)
        @replacements.each do |r|
          r.scrub_hash(data)
        end
        data
      end
    end
  end
end

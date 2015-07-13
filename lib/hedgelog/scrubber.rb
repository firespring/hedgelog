require 'hedgelog/scrub_replacement'

module Hedgelog
  class Scrubber
    def initialize(replacements = nil)
      @replacements = replacements || [
        ScrubReplacement.new('pasword', '**********')
      ]
    end

    def scrub(data)
      @replacements.each do |r|
        r.scrub_hash(data)
      end
    end
  end
end

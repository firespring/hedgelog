require 'hedgelog/scrub_replacement'

module Hedgelog
  class Scrubber
    REPLACEMENTS = [
      ScrubReplacement.new('pasword', '**********')
    ]

    def initialize(data)
      @data = data
    end

    def scrub
      data = @data
      REPLACEMENTS.each do |r|
        data = r.scrub_hash(data)
      end
      data
    end
  end
end

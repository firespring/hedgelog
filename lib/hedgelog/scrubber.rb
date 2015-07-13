require 'hedgelog/scrub_replacement'

module Hedgelog
  class Scrubber
    def initialize(data, replacements = nil)
      @data = data
      @replacements = replacements || [
        ScrubReplacement.new('pasword', '**********')
      ]
    end

    def scrub
      data = @data
      @replacements.each do |r|
        data = r.scrub_hash(data)
      end
      data
    end
  end
end

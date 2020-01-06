require 'hedgelog/scrub_replacement'

class Hedgelog
  class Scrubber
    def initialize(replacements = nil)
      @replacements = [ScrubReplacement.new('password', '**********')]
      unless replacements.nil?
        replacements.each do |x|
          if x.instance_of?(ScrubReplacement)
            @replacements << x
          else
            @replacements << ScrubReplacement.new(x,'**********')
          end
        end
      end
    end

    def scrub(data)
      # Need to Marshal.dump/Marshal.load to deep copy the input so that scrubbing doesn't change global state
      d = Marshal.load(Marshal.dump(data))
      @replacements.each do |r|
        r.scrub_hash(d)
      end
      d
    end
  end
end

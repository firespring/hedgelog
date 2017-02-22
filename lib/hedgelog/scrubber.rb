require 'hedgelog/scrub_replacement'

class Hedgelog
  class Scrubber
    def initialize(replacements = nil)
      @replacements = replacements || [
        ScrubReplacement.new('password', '**********')
      ]
    end

    # rubocop:disable Security/MarshalLoad
    def scrub(data)
      # Need to Marshal.dump/Marshal.load to deep copy the input so that scrubbing doesn't change global state
      d = Marshal.load(Marshal.dump(data))
      @replacements.each do |r|
        r.scrub_hash(d)
      end
      d
    end
    # rubocop:enable Security/MarshalLoad
  end
end

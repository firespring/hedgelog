class Hedgelog
  class ScrubReplacement
    def initialize(key, replacement)
      @key = key
      @replacement = replacement
      @match_regex = /("?)#{@key}("?[=:]\s*"?)(.+?)(["&,;\s]|$)/
    end

    def scrub_string(string)
      string.gsub!(@match_regex) do
        start = Regexp.last_match[1]
        eql = Regexp.last_match[2]
        delim = Regexp.last_match[4]
        "#{start}#{@key}#{eql}#{@replacement}#{delim}"
      end
    end

    def scrub_hash(hash)
      hash.each do |key, val|
        next hash[key] = @replacement if key.to_s.downcase == @key.to_s.downcase
        scrub_thing(val)
      end
    end

    def scrub_array(array)
      array.each do |val|
        scrub_thing(val)
      end
    end

    private

    def scrub_thing(thing)
      scrub_string(thing) if thing.is_a?(String)
      scrub_array(thing) if thing.is_a?(Array)
      scrub_hash(thing) if thing.is_a?(Hash)
    end
  end
end

class Hedgelog
  class ScrubReplacement
    def initialize(key, replacement)
      @key = key
      @replacement = replacement
      @match_regex = /("?)(#{@key})("?)(=?>?:?\s?)("?)([a-zA-Z0-9]*)("?)/
    end

    def scrub_string(string)
      string.gsub!(@match_regex) do
        quote1 = Regexp.last_match[1]
        key = Regexp.last_match[2]
        quote2 = Regexp.last_match[3]
        separator = Regexp.last_match[4]
        quote3 = Regexp.last_match[5]
        quote4 = Regexp.last_match[7]
        "#{quote1}#{key}#{quote2}#{separator}#{quote3}#{@replacement}#{quote4}"
      end
    end

    def scrub_hash(hash)
      hash.each do |key, val|
        next hash[key] = @replacement if key.to_s.casecmp(@key.to_s).zero?

        scrub_thing(val)
      end
    end

    def scrub_array(array)
      array.each do |val|
        scrub_thing(val)
      end
    end

    private def scrub_thing(thing)
      scrub_string(thing) if thing.is_a?(String)
      scrub_array(thing) if thing.is_a?(Array)
      scrub_hash(thing) if thing.is_a?(Hash)
    end
  end
end

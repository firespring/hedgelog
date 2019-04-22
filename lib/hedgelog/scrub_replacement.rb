# coding: utf-8

class Hedgelog
  class ScrubReplacement
    def initialize(key, replacement)
      @key = key
      @replacement = replacement
      @match_regex = /("?)#{@key}\1(=>|=|:)(\s*)("?)(.+?)\4(&|,|;|\s|$)/
    end

    def scrub_string(string)
      string.gsub!(@match_regex) do
        quote1 = Regexp.last_match[1]
        sep = Regexp.last_match[2]
        whitespace = Regexp.last_match[3]
        quote2 = Regexp.last_match[4]
        rest = Regexp.last_match[6]
        "#{quote1}#{@key}#{quote1}#{sep}#{whitespace}#{quote2}#{@replacement}#{quote2}#{rest}"
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

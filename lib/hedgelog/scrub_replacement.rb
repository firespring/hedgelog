module Hedgelog
  class ScrubReplacement
    def initialize(key, replacement)
      @key = key
      @replacement = replacement
    end

    def scrub_string(string)
      string.gsub(/("?)#{@key}("?[=:]\s*"?)(.+?)(["&,;\s]|$)/) do
        start = Regexp.last_match[1]
        eql = Regexp.last_match[2]
        delim = Regexp.last_match[4]
        "#{start}#{@key}#{eql}#{@replacement}#{delim}"
      end
    end

    def scrub_hash(hash)
      hash.map do |key, val|
        val = scrub_string(val) if val.is_a?(String)
        val = @replacement if key.to_s.downcase == @key.to_s.downcase 
        val = scrub_hash(val) if val.is_a?(Hash)
        [key, val]
      end.to_h
    end
    # TODO: Array
  end
end

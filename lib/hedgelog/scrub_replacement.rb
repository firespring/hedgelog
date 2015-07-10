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
        val = scrub_hash(val) if val.is_a?(Hash)
        val = scrub_array(val) if val.is_a?(Array)
        val = @replacement if key.to_s.downcase == @key.to_s.downcase
        [key, val]
      end.to_h
    end

    def scrub_array(array)
      array.map do |val|
        val = scrub_string(val) if val.is_a?(String)
        val = scrub_hash(val) if val.is_a?(Hash)
        val = scrub_array(val) if val.is_a?(Array)
        val
      end
    end
  end
end

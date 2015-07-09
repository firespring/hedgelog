module Hedgelog
  class ScrubReplacement < Struct.new(:key, :replacement)
    def scrub_string(string)
      string.gsub(/#{@key}([=:]).*([&,;\s\n\r$]*)/) do |eql, delim|
        "#{@key}#{eql}#{@replacement}#{delim}"
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

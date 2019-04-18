# coding: utf-8
require 'pry'

class Hedgelog
  class ScrubReplacement
    def initialize(key, replacement)
      @key = key
      @replacement = replacement
      #@match_regex = /("?)#{@key}\1(=>|=|:)(\s*)(\\?)("?)(.+)(?:(\\"))/
      #@match_regex = /("?)#{@key}\1(\")(=>|=|:)(\s*)("?)(.+)(\")/
      @match_regex = /(\\"|:)?#{@key}(\\"|\s)?(=>|=|:)(\s*)("?)(.+)[^,\s&;]/
    end

    def scrub_string(string)
      string.gsub!(@match_regex) do
        #quote = Regexp.last_match[1]
        #sep = Regexp.last_match[2]
        #whitespace = Regexp.last_match[3]
        # secret = Regexp.last_match[5]

        #rest = Regexp.last_match[8]

        match1 = Regexp.last_match[1]
        match2 = Regexp.last_match[2]
        match3 = Regexp.last_match[3]
        match4 = Regexp.last_match[4]
        match5 = Regexp.last_match[5]
        match6 = Regexp.last_match[6]
        match7 = Regexp.last_match[7]
        match8 = Regexp.last_match[8]

        match = ""
        math_arr = []
        rest = ""

        for i in 1..8 do
          if Regexp.last_match[i].to_s.include? "\u26A0"
            match = Regexp.last_match[i]
            match_arr = match.split("\u26A0")
            match_arr[0] << "\u26A0"
            rest = match_arr[1]
          end
        end

        #"#{quote}#{@key}#{quote}#{sep}#{whitespace}#{quote}#{quote}#{@replacement}#{quote}#{rest}"
        "#{match1}#{@key}#{match2}#{match3}#{match4}#{match5}#{@replacement}#{rest}"
        binding.pry
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

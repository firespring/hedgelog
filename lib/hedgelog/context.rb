require 'hedgelog/scrubber'

class Hedgelog
  class Context
    def initialize(scrubber, data = {})
      raise ::ArgumentError, "#{self.class}: argument must be Hash got #{data.class}." unless data.is_a? Hash
      check_reserved_keys(data)
      @data = data
      @scrubber = scrubber
    end

    def []=(key, val)
      raise ::ArgumentError, "#{self.class}: The #{key} is a reserved key and cannot be used." if Hedgelog::RESERVED_KEYS.include? key.to_sym

      @data[key] = val
    end

    def [](key)
      @data[key]
    end

    def delete(key)
      @data.delete(key)
    end

    def clear
      @data = {}
    end

    def merge(hash)
      @data.merge(hash)
    end

    def merge!(hash_or_context)
      check_reserved_keys(hash_or_context) unless hash_or_context.is_a? Hedgelog::Context

      @data = hash_or_context.to_h.merge(@data)
    end

    def overwrite!(hash_or_context)
      check_reserved_keys(hash_or_context) unless hash_or_context.is_a? Hedgelog::Context

      @data.merge!(hash_or_context.to_h)
    end

    def scrub!
      @data = @scrubber.scrub(@data)
      self
    end

    def to_h
      @data
    end

    private

    def check_reserved_keys(hash)
      invalid_keys = Hedgelog::RESERVED_KEYS & hash.keys
      raise ::ArgumentError, "#{self.class}: The following keys are reserved and cannot be used #{invalid_keys.to_a}." if invalid_keys.length > 0
    end
  end
end

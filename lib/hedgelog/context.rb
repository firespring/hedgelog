require 'hedgelog/scrubber'
require 'hedgelog/normalizer'

class Hedgelog
  class Context
    def initialize(scrubber, normalizer, data = {})
      raise ::ArgumentError, "#{self.class}: argument must be Hash got #{data.class}." unless data.is_a? Hash
      check_reserved_keys(data)
      @data = data
      @scrubber = scrubber
      @normalizer = normalizer 
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

      hash_or_context = hash_or_context.to_h if hash_or_context.respond_to?(:to_h)
      @data = hash_or_context.merge(@data)
    end

    def overwrite!(hash_or_context)
      check_reserved_keys(hash_or_context) unless hash_or_context.is_a? Hedgelog::Context

      hash_or_context = hash_or_context.to_h if hash_or_context.respond_to?(:to_h)
      @data.merge!(hash_or_context)
    end

    def scrub!
      @data = @scrubber.scrub(@data)
      self
    end

    def normalize!
      @data = @normalizer.normalize(@data)
      self
    end

    def to_h
      @data
    end

    private

    def check_reserved_keys(hash)
      invalid_keys = Hedgelog::RESERVED_KEYS & hash.keys
      raise ::ArgumentError, "#{self.class}: The following keys are reserved and cannot be used #{invalid_keys.to_a}." unless invalid_keys.empty?
    end
  end
end

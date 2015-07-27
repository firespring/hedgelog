require 'hedgelog/version'
require 'hedgelog/scrubber'
require 'logger'
require 'yajl'

module Hedgelog
  class Channel
    LEVELS = %w(DEBUG INFO WARN ERROR FATAL UNKNOWN).each_with_object({}).with_index do |(v, h), i|
      h[v] = i
      h[v.downcase] = i
      h[v.to_sym] = i
      h[v.downcase.to_sym] = i
      h[i] = v.downcase.to_sym
    end.freeze

    TOP_LEVEL_KEYS = Set.new([:app, :channel, :level, :level_name, :message, :request_id, :timestamp]).freeze
    RESERVED_KEYS = Set.new([:app, :level, :level_name, :timestamp, :context, :caller]).freeze

    TIMESTAMP_FORMAT = '%Y-%m-%dT%H:%M:%S.%6N'.freeze
    BACKTRACE_RE = /([^:]+):([0-9]+)(?::in `(.*)')?/

    def initialize(logdev = STDOUT, shift_age = nil, shift_size = nil)
      @channel_context = {}
      @level = LEVELS[:debug]
      @channel = nil
      @logdev = nil
      @scrubber = Scrubber.new

      if logdev.is_a?(self.class)
        @channel = logdev
      else
        @logdev = Logger::LogDevice.new(logdev, shift_age: shift_age, shift_size: shift_size)
      end
    end

    attr_reader :level

    def level=(level)
      level = level_to_int(level)
      @level = level
    end

    def add(severity, message = nil, progname = nil, context = {}, &block)
      severity ||= LEVELS[:unknown]
      return true if (@logdev.nil? && @channel.nil?) || severity < @level

      message, context = *block.call if block
      context ||= {}

      context = @channel_context.merge(context)
      context[:message] ||= message

      check_invalid_keys(context)

      return write(severity, context) if @logdev

      @channel.add(severity, nil, progname, context) if @channel
    end

    def []=(key, val)
      @channel_context[key] = val
    end

    def [](key)
      @channel_context[key]
    end

    def delete(key)
      @channel_context.delete(key)
    end

    def clear_channel_context
      @channel_context = {}
    end

    def channel(name)
      sc = self.class.new(self)
      sc.level = @level
      channel_name = name
      channel_name = "#{self[:channel]} => #{name}" if self[:channel]
      sc[:channel] = channel_name
      sc
    end

    %w(fatal error warn info debug unknown).each do |level|
      predicate = "#{level}?".to_sym
      level = level.to_sym

      define_method(level) do |message = nil, context = {}, &block|
        raise ::ArgumentError, "#{self.class}##{level} requires at least 1 argument or a block" if !message && !block
        raise ::ArgumentError, "#{self.class}##{level} requires either a message OR a block" if message && block
        raise ::ArgumentError, "#{self.class}##{level} context is a #{context.class}, it must be a Hash" unless context.is_a?(Hash)

        return true unless send(predicate)

        add(level_to_int(level), message, nil, context, &block)
      end

      define_method(predicate) do
        level_to_int(level) >= @level
      end
    end

    private

    def level_to_int(level)
      return level if level.is_a?(Fixnum)
      LEVELS[level]
    end

    def level_from_int(level)
      return LEVELS[level] if level.is_a?(Fixnum)
      level.to_sym
    end

    def check_invalid_keys(context)
      invalid_keys = RESERVED_KEYS & context.keys
      raise ::ArgumentError, "#{self.class}: The following keys are reserved and cannot be used #{invalid_keys.to_a}." if invalid_keys.length > 0
    end

    def write(severity, context)
      return true if @logdev.nil?

      context = @scrubber.scrub(context)
      context.merge!(
        timestamp: Time.now.strftime(TIMESTAMP_FORMAT),
        level: level_from_int(severity)
      )
      context[:caller] = debugharder(caller[3]) if debug?

      data = extract_top_level_keys(context)
      @logdev.write(Yajl::Encoder.encode(data) + "\n")
    end

    def extract_top_level_keys(context)
      data = {}
      TOP_LEVEL_KEYS.each do |key|
        data[key] = context.delete(key) if context.key? key
      end
      data[:context] = context
      data
    end

    def debugharder(callinfo)
      m = BACKTRACE_RE.match(callinfo)
      return unless m
      path, line, method = m[1..3]
      whence = $LOAD_PATH.find { |p| path.start_with?(p) }
      if whence
        # Remove the RUBYLIB path portion of the full file name
        file = path[whence.length + 1..-1]
      else
        # We get here if the path is not in $:
        file = path
      end

      {
        file: file,
        line: line,
        method: method
      }
    end
  end
end

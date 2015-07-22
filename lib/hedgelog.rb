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

    TIMESTAMP_FORMAT = '%Y-%m-%dT%H:%M:%S.%6N'.freeze
    BACKTRACE_RE = /([^:]+):([0-9]+)(?::in `(.*)')?/

    def initialize(logdev = STDOUT, shift_age = nil, shift_size = nil)
      @context = {}
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

    def add(severity, message = nil, progname = nil, data = {}, &block)
      severity ||= LEVELS[:unknown]
      return true if (@logdev.nil? && @channel.nil?) || severity < @level

      message, data = *block.call if block
      data ||= {}

      data = @context.merge(data)
      data[:message] ||= message

      return write(severity, data) if @logdev

      @channel.add(severity, message, progname, data) if @channel
    end

    def []=(key, val)
      @context[key] = val
    end

    def [](key)
      @context[key]
    end

    def delete(key)
      @context.delete(key)
    end

    def clear_context
      @context = {}
    end

    def subchannel(name)
      sc = self.class.new(self)
      sc.level = @level
      subchannel_name = name
      subchannel_name = "#{self[:subchannel]} => #{name}" if self[:subchannel]
      sc[:subchannel] = subchannel_name
      sc
    end

    %w(fatal error warn info debug unknown).each do |level|
      predicate = "#{level}?".to_sym
      level = level.to_sym

      define_method(level) do |message = nil, data = {}, &block|
        raise ::ArgumentError, "#{self.class}##{level}(message, data={}, &block) requires at least 1 argument or a block" if !message && !block
        raise ::ArgumentError, "#{self.class}##{level}(message, data={}, &block) requires either a message OR a block" if message && block
        raise ::ArgumentError, "#{self.class}##{level}(message, data={}, &block) data was a #{data.class}, it must be a Hash" unless data.is_a?(Hash)

        return true unless send(predicate)

        add(level_to_int(level), message, nil, data, &block)
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

    def write(severity, data)
      return true if @logdev.nil?

      data = @scrubber.scrub(data)
      data.merge!(
        timestamp: Time.now.strftime(TIMESTAMP_FORMAT),
        level: level_from_int(severity)
      )
      data[:caller] = debugharder(caller[3]) if debug?
      # @logdev.write(Oj.dump(data, mode: :compat) + "\n")
      # @logdev.write(data.to_json + "\n")
      @logdev.write(Yajl::Encoder.encode(data) + "\n")
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

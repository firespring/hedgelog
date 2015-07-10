require 'hedgelog/version'
require 'hedgelog/scrubber'
require 'logger'
require 'json'

module Hedgelog
  class Channel
    LEVELS = %w(DEBUG INFO WARN ERROR FATAL).each_with_object({}).with_index do |(v, h), i|
      h[v] = i
      h[v.downcase] = i
      h[v.to_sym] = i
      h[v.downcase.to_sym] = i
    end
    TIMESTAMP_FORMAT = '%Y-%m-%dT%H:%M:%S.%6N'.freeze
    BACKTRACE_RE = /([^:]+):([0-9]+)(?::in `(.*)')?/

    def initialize(output = STDOUT)
      @context = {}
      @level = ::Logger::DEBUG

      if output.is_a?(self.class)
        @logger = output
      else
        @logger = ::Logger.new(output)
        @logger.formatter = proc { |_severity, _datetime, _progname, msg| "#{msg}\n" }
      end
    end

    attr_reader :level

    def level=(level)
      level = level_to_int(level)
      @level = level
      @logger.level = level if @logger.is_a?(Logger)
    end

    def add(severity, message = nil, progname = nil)
      @logger.add(severity, message, progname)
    end

    def []=(key, val)
      @context[key] = val
    end

    def [](key)
      @context[key]
    end

    def clear_context
      @context = {}
    end

    def subchannel(name)
      sc = self.class.new(self)
      sc.level = @level
      sc[:subchannel] = name
      sc
    end

    %w(fatal error warn info debug).each do |level|
      predicate = "#{level}?".to_sym
      level = level.to_sym

      define_method(level) do |message = nil, data = {}, &block|
        raise ::ArgumentError, "#{self.class}##{level}(message, data={}, &block) requires at least 1 argument or a block" if !message && !block
        raise ::ArgumentError, "#{self.class}##{level}(message, data={}, &block) requires either a message OR a block" if message && block
        raise ::ArgumentError, "#{self.class}##{level}(message, data={}, &block) data was a #{data.class}, it must be a Hash" unless data.is_a?(Hash)

        return send(level, *block.call) if block

        log_with_level(level, message, data) if send(predicate)
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

    def log_with_level(level, message = nil, data = nil)
      data ||= {}
      data = data.merge(@context)
      data[:level] = level
      data[:message] = message
      data[:timestamp] = Time.now.strftime(TIMESTAMP_FORMAT)
      data = data.merge(debugharder(caller[2])) if debug?
      data = Scrubber.new(data).scrub
      add(level_to_int(level), data.to_json)
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

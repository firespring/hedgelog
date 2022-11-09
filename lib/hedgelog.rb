# frozen_string_literal: true

require 'hedgelog/version'
require 'hedgelog/context'
require 'hedgelog/scrubber'
require 'hedgelog/normalizer'
require 'logger'
require 'yajl'

class Hedgelog
  LEVELS = %w[DEBUG INFO WARN ERROR FATAL UNKNOWN].each_with_object({}).with_index do |(v, h), i|
    h[v] = i
    h[v.downcase] = i
    h[v.to_sym] = i
    h[v.downcase.to_sym] = i
    h[i] = v.downcase.to_sym
  end.freeze

  TOP_LEVEL_KEYS = %i[app channel level level_name message request_id timestamp].freeze
  RESERVED_KEYS = %i[app level level_name timestamp context caller].freeze

  TIMESTAMP_FORMAT = '%Y-%m-%dT%H:%M:%S.%6N%z'
  BACKTRACE_RE = Regexp.new("([^:]+):([0-9]+)(?::in `(.*)')?")

  attr_reader :level
  attr_writer :app

  def initialize(logdev = $stdout, shift_age = nil, shift_size = nil)
    @level = LEVELS[:debug]
    @channel = nil
    @logdev = nil
    @app = nil
    @scrubber = Hedgelog::Scrubber.new
    @normalizer = Hedgelog::Normalizer.new
    @channel_context = Hedgelog::Context.new(@scrubber, @normalizer)

    if logdev.is_a?(self.class)
      @channel = logdev
    else
      @logdev = Logger::LogDevice.new(logdev, shift_age: shift_age, shift_size: shift_size)
    end
  end

  def level=(level)
    int_level = level_to_int(level)
    raise ::ArgumentError, "#{self.class}#level= , #{level} is not a valid level." if int_level.nil?

    @level = int_level
  end

  # rubocop:disable Metrics/ParameterLists
  def add(severity = LEVELS[:unknown], message = nil, progname = nil, context = {}, &block)
    return true if (@logdev.nil? && @channel.nil?) || severity < @level

    message, context = *yield if block
    context ||= {}

    context = Hedgelog::Context.new(@scrubber, @normalizer, context) unless context.is_a? Hedgelog::Context
    context.merge!(@channel_context)
    context[:message] ||= message

    return write(severity, context) if @logdev

    @channel&.add(severity, nil, progname, context)
  end
  # rubocop:enable Metrics/ParameterLists

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

  %w[fatal error warn info debug unknown].each do |level|
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

  def silence(temporary_level = LEVELS[:error])
    old_level = level
    self.level = temporary_level

    yield self
  ensure
    self.level = old_level
  end

  def formatter
    ::Logger::Formatter.new
  end

  def formatter=(_value)
    formatter
  end

  private def level_to_int(level)
    return level if level.is_a?(Integer)

    LEVELS[level]
  end

  private def level_from_int(level)
    return LEVELS[level] if level.is_a?(Integer)

    level.to_sym
  end

  private def write(severity, context)
    return true if @logdev.nil?

    context.normalize!
    context.scrub!

    data = context.merge(default_data(severity))
    data[:app] = @app if @app
    data[:caller] = debugharder(caller(4, 1).first) if debug?
    data = extract_top_level_keys(data)

    @logdev.write("#{Yajl::Encoder.encode(data)}\n")
    true
  end

  private def default_data(severity)
    {
      timestamp: Time.now.strftime(TIMESTAMP_FORMAT),
      level_name: level_from_int(severity),
      level: severity
    }
  end

  private def extract_top_level_keys(context)
    data = {}
    TOP_LEVEL_KEYS.each do |key|
      data[key] = context.delete(key) if context.key? key
    end
    data[:context] = context
    data
  end

  private def debugharder(callinfo)
    m = BACKTRACE_RE.match(callinfo)
    return unless m

    path, line, method = m[1..3]
    whence = $LOAD_PATH.find { |p| path.start_with?(p) }
    file = if whence
             # Remove the RUBYLIB path portion of the full file name
             path[whence.length + 1..]
           else
             # We get here if the path is not in $:
             path
           end

    {
      file: file,
      line: line,
      method: method
    }
  end
end

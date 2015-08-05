# Hedgelog
[![Build Status](https://travis-ci.org/firespring/hedgelog.svg)](https://travis-ci.org/firespring/hedgelog)

This gem provides an opinionated Ruby logger for writing structured JSON logs. It attempts to maintain compatibility with the standard Ruby logger api while extending it with functionality relevant to JSON logging.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hedgelog'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hedgelog

## Basic Usage

```ruby
require 'hedgelog'

# Logging defaults to STDOUT or you can pass a file path to .new
logger = Hedgelog::Channel.new

logger.level = :info

logger.debug "Foo"
# No Output

logger.info "Foo"
=> {"message":"FOO","timestamp":"2015-07-15T12:03:08.257356","level_name":"info","level":1}

logger.info "FOO", sample: 'data'
=> {"context": {"sample":"data"},"message":"FOO","timestamp":"2015-07-15T12:05:02.302202","level_name":"info","level":1}

# It also supports logging as a block with extra data
logger.info { ["FOO", {sample: 'data'}] }
=> {"context", {"sample":"data"},"message":"FOO","timestamp":"2015-07-15T12:06:20.026807","level_name":"info","level":1}
```

## Context

Hedgelog allows adding additional context to an instance of a logger that will get output with each log message

```ruby
logger[:request_id] = 1234
=> 1234
logger.info "FOO"
=> {"request_id":1234,"message":"FOO","timestamp":"2015-07-15T12:09:33.129984","level_name":"info","level":1}
```

## Sub-channels

One of the primary features of Hedgelog is the usage of sub-channels.

Sub-channels can have their own context separate from the main loggers context. This allows including additional information for all log messages from a portion of your application.

```ruby
subchannel = logger.subchannel(:database)
subchannel.info "FOO"
=> {"subchannel":"database","message":"FOO","timestamp":"2015-07-15T12:12:39.147210","level_name":"info","level":1}

# The subchannel does not effect the primary instance of the logger
logger.info "FOO"
=>{"message":"FOO","timestamp":"2015-07-15T12:13:31.132059","level_name":"info","level":1}
```

The sub-channel instances conform to the same interface as Hedgelog. Therefore they can be passed in as standard Ruby loggers to gems that take an instance of Ruby logger for input.

```ruby
DataMapper.logger = logger.subchannel(:database)
```

## Scrubbing

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/firespring/hedgelog.

For details on the pull request process please see our [contributing documentation](CONTRIBUTING.md)

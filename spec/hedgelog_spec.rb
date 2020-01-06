require 'spec_helper'
require 'timecop'
require 'benchmark/ips'
require 'json'

describe Hedgelog do
  it 'has a version number' do
    expect(Hedgelog::VERSION).not_to be nil
  end

  let(:log_dev) { StringIO.new }
  let(:log_level) { Logger::INFO }
  let(:logger) { Hedgelog.new(log_dev) }
  let(:log_exec) { -> { logger.debug 'foo' } }
  let(:log_results) { log_dev.string }
  subject do
    log_exec.call
    logger.level = log_level
    JSON.parse(log_results)
  end

  %w[debug info warn error fatal unknown].each do |level|
    describe "\##{level}" do
      let(:log_level) { level.to_sym }
      before :each do
        Timecop.freeze(2015, 1, 1)
      end

      after :each do
        Timecop.return
      end

      context 'when log input is the string "FOO" the output' do
        let(:log_exec) { -> { logger.fatal 'FOO' } }

        it do
          should include(
            'message' => 'FOO',
            'timestamp' => Time.now.strftime(Hedgelog::TIMESTAMP_FORMAT),
            'level_name' => 'fatal',
            'level' => 4
          )
        end
      end

      context 'when log input is a block containing the string "FOO" the output' do
        let(:log_exec) { -> { logger.fatal { 'FOO' } } }

        it do
          should include(
            'message' => 'FOO',
            'timestamp' => Time.now.strftime(Hedgelog::TIMESTAMP_FORMAT),
            'level_name' => 'fatal',
            'level' => 4
          )
        end
      end
    end
  end

  describe '#add' do
    subject do
      logger = Hedgelog.new(log_dev,nil,nil,scrubber)
      logger.level = log_level
      logger.add(severity, message, progname, data, &block)
    end
    let(:message) { 'Foo' }
    let(:progname) { nil }
    let(:data) { {} }
    let(:block) { nil }
    let(:severity) { 1 }
    let(:scrubber) {nil}
    let(:wash) { '**********' }

    context 'when the severity is lower than the log level' do
      let(:log_level) { Logger::FATAL }

      it { should be true }
    end

    context 'when logging with only a message' do
      it 'writes the message in the json hash' do
        subject
        expect(JSON.parse(log_results)).to include('message' => 'Foo')
      end
    end

    context 'when logging with a message and data' do
      let(:data) { {bar: 'baz', secret:'secret', password: 'do not see me'} }

      it 'writes the message in the json hash should not be able to see password' do
        subject
        expect(JSON.parse(log_results)).to include('message' => 'Foo')
        expect(JSON.parse(log_results)['context']).to include('bar' => 'baz', 'secret' => 'secret', 'password' => wash)
      end

      context 'When the scrubber is a string array' do
        let(:scrubber) { ['secret'] }

        it 'writes the message and hash context while wiping secret info' do
          subject
          expect(JSON.parse(log_results)).to include('message' => 'Foo')
          expect(JSON.parse(log_results)['context']).to include('bar' => 'baz','secret' => wash, 'password' => wash)
        end

      end
      ''
      context 'When the scrubber is a ScrubReplacement array' do

        let(:scrubber) { [Hedgelog::ScrubReplacement.new('secret', wash)] }

        it 'writes message and hash context wipes secret and password' do
        subject
        expect(JSON.parse(log_results)).to include('message' => 'Foo')
        expect(JSON.parse(log_results)['context']).to include('bar' => 'baz')
        expect(JSON.parse(log_results)['context']).to include('secret' => wash)
        expect(JSON.parse(log_results)['context']).to include('password' => wash)
        end
      end

      context 'When the scrubber is a mixed array' do
        let(:data) { {bar: 'baz', secret:'secret', password:'do not see me', mysterious:'hidden'} }
        let(:scrubber) { [Hedgelog::ScrubReplacement.new('secret', wash), 'mysterious']}

        it 'writes message and hash context wipes secret, password, and mysterious' do
          subject
          expect(JSON.parse(log_results)).to include('message' => 'Foo')
          expect(JSON.parse(log_results)['context']).to include('bar' => 'baz')
          expect(JSON.parse(log_results)['context']).to include('secret' => wash)
          expect(JSON.parse(log_results)['context']).to include('password' => wash)
          expect(JSON.parse(log_results)['context']).to include('mysterious' => wash)
        end
      end
    end

    context 'when logging with a string only block' do
      let(:message) { nil }
      let(:block) { -> { 'Foo' } }

      it 'writes the message in the json hash' do
        subject
        expect(JSON.parse(log_results)).to include('message' => 'Foo')
      end
    end

    context 'when logging with a string and data block' do
      let(:message) { nil }
      let(:block) { -> { ['Foo', {bar: 'baz'}] } }

      it 'writes the message in the json hash' do
        subject
        expect(JSON.parse(log_results)).to include('message' => 'Foo')
        expect(JSON.parse(log_results)['context']).to include('bar' => 'baz')
      end
    end

    context 'when logging with only a severity' do
      subject do
        logger = Hedgelog.new(log_dev)
        logger.level = log_level
        logger.add(severity) { message }
      end
      let(:log_level) { Logger::DEBUG }

      it 'sets the appropriate level on the log' do
        subject
        expect(JSON.parse(log_results)).to include('message' => message)
        expect(JSON.parse(log_results)).to include('level' => severity)
      end
    end

    context 'when logging to a channel' do
      let(:logger) { Hedgelog.new(log_dev) }
      subject do
        logger.level = log_level
        channel = logger.channel(:channel)
        channel.add(severity, message, progname, data, &block)
      end

      it 'calls .add recursively on the channel' do
        expect(logger).to receive(:add).with(severity, nil, nil, anything)
        subject
      end
    end
  end

  describe 'silence' do
    let(:log_level) { :debug }
    let(:log_exec) { -> { logger.silence(Logger::INFO) { logger.debug 'Foo' } } }

    it 'silences the log' do
      log_exec.call
      expect(log_dev.string).to be_empty
    end
  end

  describe "when the channel's level is higher than the called level" do
    let(:log_level) { :info }

    it 'is not log the message' do
      expect(log_results).to be_empty
    end

    context 'and the logger is passed a block' do
      let(:log_exec) { -> { logger.debug { raise Exception, 'This is not be evaluated' } } }

      it 'does not log the message' do
        expect(log_results).to be_empty
      end
    end
  end

  describe 'app' do
    context 'when app is set' do
      let(:logger) do
        logger = Hedgelog.new(log_dev)
        logger.app = 'test_app'
        logger
      end

      it 'logs the app name with each log message' do
        expect(subject).to include('app' => 'test_app')
      end
    end
    context 'when app is not set' do
      it 'does not include app in the log message' do
        expect(subject.key?('app')).to be false
      end
    end
  end

  describe 'context' do
    context 'with context set on the channel' do
      before :each do
        logger[:foo] = 'bar'
      end
      it 'returns the set context when used like a hash' do
        expect(logger[:foo]).to eq 'bar'
      end
      it 'contains the context under the "context" key' do
        expect(subject['context']).to include('foo' => 'bar')
      end
    end
    context 'when deleting something from the context' do
      before :each do
        logger[:foo] = 'bar'
        logger.delete(:foo)
      end
      it 'does not return the value  when used like a hash' do
        expect(logger[:foo]).to_not eq 'bar'
      end
      it 'does not contain the context under the "context" key' do
        expect(subject['context']).to_not include('foo' => 'bar')
      end
    end
  end

  # This test is just for coverage
  describe '#level_from_int' do
    it 'returns a symbol for the level name, given the related integer' do
      expect(logger.send(:level_from_int, 0)).to eq :debug
    end
    it 'returns a symbol if a symbol or string are passed in' do
      expect(logger.send(:level_from_int, :debug)).to eq :debug
      expect(logger.send(:level_from_int, 'debug')).to eq :debug
    end
  end

  # This test is just for coverage
  describe '#debugharder' do
    let(:callinfo) { '' }

    context 'when the path is out of the load path' do
      it 'doesnt explode' do
        expect(Hedgelog::BACKTRACE_RE).to receive(:match).with(callinfo) { [] }
        expect($LOAD_PATH).to receive(:find) { false }
        logger.send(:debugharder, callinfo)
      end
    end
  end

  describe '#channel' do
    let(:channel) do
      logger.channel('channel')
    end
    subject do
      channel.debug 'Foo'
      JSON.parse(log_dev.string)
    end

    it { should include('channel' => 'channel') }

    context 'with context on the main channel' do
      before :each do
        logger[:c1] = 'test'
      end
      after :each do
        logger.clear_channel_context
      end

      it 'includes the context under the "context" key' do
        expect(subject['context']).to include('c1' => 'test')
      end
    end

    context 'with context on the channel' do
      before :each do
        channel[:c2] = 'test'
      end
      after :each do
        channel.clear_channel_context
      end

      it 'includes the context under the "context" key' do
        expect(subject['context']).to include('c2' => 'test')
      end
    end

    context 'when channels are nested' do
      let(:channel) do
        logger.channel('channel').channel('nested_channel')
      end

      it { should include('channel' => 'channel => nested_channel') }
    end
  end

  describe 'performance' do
    let(:log_dev) { '/dev/null' }
    let(:standard_logger) { Logger.new(log_dev) }
    let(:hedgelog_logger) { Hedgelog.new(log_dev) }
    let(:message) { 'log message' }
    let(:hedgelog_params) { [message] }

    before :each do
      standard_logger.level = level
      hedgelog_logger.level = level
    end

    shared_context 'logging with context' do
      let(:hash) { {message: 'dummy=1234'} }
      let(:array) { ['dummy string', {message: 'dummy=1234'}] }
      let(:context) { hash }
      let(:hedgelog_params) { [message, context] }
      before :each do
        # add other types to the hash
        context[:hash] = hash.clone
        context[:array] = array
        context[:string] = 'dummy'
        context[:number] = 1234
      end
    end

    context 'when in debug mode' do
      let(:level) { Logger::DEBUG }
      context 'when logging a string' do
        it 'is no more than 12x slower than the stdlib logger' do
          expect { standard_logger.debug(message) }.to(perform.times_slower(12).than { hedgelog_logger.debug(*hedgelog_params) })
        end
      end
      context 'when logging with context' do
        include_context 'logging with context'

        it 'is no more than 16x slower than the stdlib logger' do
          expect { standard_logger.debug(message) }.to(perform.times_slower(16).than { hedgelog_logger.debug(*hedgelog_params) })
        end
      end
    end
    context 'when not in debug mode' do
      let(:level) { Logger::INFO }
      context 'when logging a string' do
        it 'is no more than 5x slower than the stdlib logger' do
          expect { standard_logger.info(message) }.to(perform.times_slower(5).than { hedgelog_logger.info(*hedgelog_params) })
        end
      end
      context 'when logging with context' do
        include_context 'logging with context'

        it 'is no more than 12x slower than the stdlib logger' do
          expect { standard_logger.info(message) }.to(perform.times_slower(12).than { hedgelog_logger.info(*hedgelog_params) })
        end
      end
    end
  end
end

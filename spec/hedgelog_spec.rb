require 'spec_helper'
require 'timecop'
require 'benchmark'
require 'oj'

describe Hedgelog do
  it 'has a version number' do
    expect(Hedgelog::VERSION).not_to be nil
  end

  %w(debug info warn error fatal).each do |level|
    let(:log_dev) { StringIO.new }
    let(:log_block) {}

    describe "\##{level}" do
      before :each do
        Timecop.freeze(2015, 01, 01)
        Hedgelog::Channel.new(log_dev).send(level, *log_call, &log_block)
      end

      after :each do
        Timecop.return
      end

      subject { Oj.load(log_dev.string) }

      context 'when log input is the string "FOO" the output' do
        let(:string) { 'FOO' }
        let(:log_call) { [string] }

        it do
          should include(
            'message' => string,
            'timestamp' => Time.now.strftime(Hedgelog::Channel::TIMESTAMP_FORMAT),
            'level' => level
          )
        end
      end

      context 'when log input is a block containing the string "FOO" the output' do
        let(:string) { 'FOO' }
        let(:log_call) { [] }
        let(:log_block) { -> { 'FOO' } }

        it do
          should include(
            'message' => string,
            'timestamp' => Time.now.strftime(Hedgelog::Channel::TIMESTAMP_FORMAT),
            'level' => level
          )
        end
      end
    end
  end

  describe "when the channel's level is higher than the called level" do
    subject { log_dev.string }
    let(:log_dev) { StringIO.new }
    let(:log_exec) { logger.debug 'foo' }
    let(:logger) do
      logger = Hedgelog::Channel.new(log_dev)
      logger.level = Logger::INFO
      logger
    end

    it 'is not log the message' do
      log_exec
      expect(subject).to be_empty
    end

    context 'and the logger is passed a block' do
      let(:log_exec) { logger.debug { raise Exception, 'This is not be evaluated' } }

      it 'does not log the message' do
        log_exec
        expect(subject).to be_empty
      end
    end
  end

  describe '#subchannel' do
    let(:log_dev) { StringIO.new }
    subject do
      subchannel.debug 'Foo'
      Oj.load(log_dev.string)
    end
    let(:main_logger) do
      Hedgelog::Channel.new(log_dev)
    end
    let(:subchannel) do
      main_logger.subchannel('subchannel')
    end

    it { should include('subchannel' => 'subchannel') }

    context 'with context on the main channel' do
      before :each do
        main_logger[:c1] = 'test'
      end
      after :each do
        main_logger.clear_context
      end

      it { should include('c1' => 'test') }
    end

    context 'with context on the subchannel' do
      before :each do
        subchannel[:c2] = 'test'
      end
      after :each do
        subchannel.clear_context
      end

      it { should include('c2' => 'test') }
    end
  end

  describe 'performance' do
    let(:log_dev) { '/dev/null' }
    let(:standard_logger) { Logger.new(log_dev) }
    let(:hedgelog_logger) { Hedgelog::Channel.new(log_dev) }

    context 'when logging a string' do
      let(:message) { 'log message' }

      context 'when in debug mode' do
        it 'is not be more than 7.5x slower than standard ruby logger' do
          standard_benchmark = Benchmark.realtime { 1000.times { standard_logger.debug(message) } }
          hedgelog_benchmark = Benchmark.realtime { 1000.times { hedgelog_logger.debug(message) } }

          expect(hedgelog_benchmark).to be <= standard_benchmark * 7.5
        end
      end

      context 'when not in debug mode' do
        let(:standard_logger) do
          logger = Logger.new(log_dev)
          logger.level = Logger::INFO
          logger
        end
        let(:hedgelog_logger) do
          logger = Hedgelog::Channel.new(log_dev)
          logger.level = Logger::INFO
          logger
        end

        it 'is not be more than 3x slower than standard ruby logger' do
          standard_benchmark = Benchmark.realtime { 1000.times { standard_logger.info(message) } }
          hedgelog_benchmark = Benchmark.realtime { 1000.times { hedgelog_logger.info(message) } }

          expect(hedgelog_benchmark).to be <= standard_benchmark * 3
        end
      end
    end
  end
end

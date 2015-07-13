require 'spec_helper'
require 'timecop'
require 'benchmark'

describe Hedgelog do
  it 'has a version number' do
    expect(Hedgelog::VERSION).not_to be nil
  end

  %w(debug info warn error fatal).each do |level|
    let(:log_dev) { StringIO.new }

    describe "\##{level}" do
      before :each do
        Timecop.freeze(2015, 01, 01)
        Hedgelog::Channel.new(log_dev).send(level, *log_call)
      end

      after :each do
        Timecop.return
      end

      subject { JSON.parse(log_dev.string) }

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
    end
  end

  describe 'performance' do
    let(:log_dev) { '/dev/null' }
    let(:standard_logger) { Logger.new(log_dev) }
    let(:hedgelog_logger) { Hedgelog::Channel.new(log_dev) }

    context 'when logging a string' do
      let(:message) { 'log message' }

      context 'when in debug mode' do
        it 'should not be more than 10x slower than standard ruby logger' do
          standard_benchmark = Benchmark.realtime { 1000.times { standard_logger.debug(message) } }
          hedgelog_benchmark = Benchmark.realtime { 1000.times { hedgelog_logger.debug(message) } }

          expect(hedgelog_benchmark).to be <= standard_benchmark * 10
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

        it 'should not be more than 4x slower than standard ruby logger' do
          standard_benchmark = Benchmark.realtime { 1000.times { standard_logger.info(message) } }
          hedgelog_benchmark = Benchmark.realtime { 1000.times { hedgelog_logger.info(message) } }

          expect(hedgelog_benchmark).to be <= standard_benchmark * 4
        end
      end
    end
  end
end

require 'spec_helper'
require 'timecop'

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
end

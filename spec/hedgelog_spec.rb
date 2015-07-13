require 'spec_helper'

describe Hedgelog do
  it 'has a version number' do
    expect(Hedgelog::VERSION).not_to be nil
  end

  %w(debug info warn error fatal).each do |level|
    let(:log_dev) { StringIO.new }

    describe "\##{level}" do
      before :each do
        Hedgelog::Channel.new(log_dev).send(level, *log_call)
      end

      subject{ JSON.parse(log_dev.string) }

      context 'when log input is the string "FOO" the output' do
        let(:string) { "FOO" }
        let(:log_call) { [string] }

        it { should include("message" => string) }
      end
    end
  end
end

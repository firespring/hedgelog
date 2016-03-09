require 'spec_helper'
require 'hedgelog/transforms/scrubber'

dummy_scrubber = Hedgelog::Transforms::ScrubReplacement.new(:dummy, 'DUMMY')

describe Hedgelog::Transforms::Scrubber do
  describe '#transform' do
    subject { described_class.new(replacements).transform(data) }

    let(:replacements) { [dummy_scrubber] }
    let(:data) { {message: 'dummy=1234'} }

    it 'calls #scrub_hash on all scrubbers' do
      expect(dummy_scrubber).to receive(:scrub_hash).with(data)
      subject
    end

    it 'returns the scrubbed data' do
      expect(subject).to include(message: 'dummy=DUMMY')
    end
  end
end

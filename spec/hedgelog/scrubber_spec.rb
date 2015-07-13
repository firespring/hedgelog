require 'spec_helper'
require 'hedgelog/scrubber'

dummy_scrubber = Hedgelog::ScrubReplacement.new(:dummy, 'DUMMY')

describe Hedgelog::Scrubber do
  describe '#scrub' do
    subject { Hedgelog::Scrubber.new(replacements).scrub(data) }

    let(:replacements) { [dummy_scrubber] }
    let(:data) { {message: 'dummy=1234'} }

    it 'calls #scrub_hash on all scrubbers' do
      expect(dummy_scrubber).to receive(:scrub_hash).with(data)
      subject
    end

    it 'returns the scrubbed data' do
      expect(subject).to include(message: 'dummy=DUMMY')
    end

    it 'does not modify external state' do
      myvar = 'dummy=1234'
      orig_myvar = myvar.clone

      data = {foo: myvar}
      Hedgelog::Scrubber.new(replacements).scrub(data)
      expect(myvar).to eq orig_myvar
    end
  end
end

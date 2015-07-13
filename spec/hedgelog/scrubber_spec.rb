require 'spec_helper'
require 'hedgelog/scrubber'

dummy_scrubber = Hedgelog::ScrubReplacement.new(:dummy, "DUMMY")

describe Hedgelog::Scrubber do
  describe '#scrub' do
    subject { Hedgelog::Scrubber.new(data, replacements).scrub }

    let(:replacements) { [dummy_scrubber] }
    let(:data) { {message: "dummy=1234"} }

    it 'calls #scrub_hash on all scrubbers' do
      expect(dummy_scrubber).to receive(:scrub_hash).with(data)
      subject
    end

    it 'returns the scrubbed output' do
      expect(subject).to include(message: "dummy=DUMMY")
    end

  end
end

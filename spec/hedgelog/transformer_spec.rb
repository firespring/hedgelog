require 'spec_helper'
require 'hedgelog/transformer'
require 'hedgelog/transforms/scrubber'

dummy_scrubber_replacement = Hedgelog::Transforms::ScrubReplacement.new(:dummy, 'DUMMY')
dummy_scrubber = Hedgelog::Transforms::Scrubber.new([dummy_scrubber_replacement])

describe Hedgelog::Transformer do
  describe '#transform' do
    subject { described_class.new(dummy_scrubber).transform(data) }
    let(:data) { {foo: 'dummy=1234'} }

    it 'runs each transform on the data' do
      expect(subject).to eq(foo: 'dummy=DUMMY')
    end

    it 'does not modify external state' do
      myvar = 'dummy=1234'
      orig_myvar = myvar.clone

      data = {foo: myvar}
      described_class.new(dummy_scrubber).transform(data)
      expect(myvar).to eq orig_myvar
    end
  end
end

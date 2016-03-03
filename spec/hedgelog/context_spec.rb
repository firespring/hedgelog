require 'spec_helper'
require 'hedgelog/context'

dummy_scrubber = Hedgelog::ScrubReplacement.new(:dummy, 'DUMMY')
dummy_normalizer = Hedgelog::Normalizer.new

describe Hedgelog::Context do
  describe '#[]=' do
    subject(:instance) { described_class.new(dummy_scrubber, dummy_normalizer, data) }
    subject(:instance_with_value) do
      instance[key] = val
      instance
    end
    subject(:data) { {} }

    context 'when key is a valid key' do
      let(:key) { :foo }
      let(:val) { 'bar' }
      it 'sets the value on the context' do
        expect(instance_with_value[:foo]).to eq 'bar'
      end
    end
    context 'when key is a reserved key' do
      let(:key) { :app }
      let(:val) { 'bar' }
      it 'raises an error' do
        expect { instance_with_value }.to raise_error(::ArgumentError)
      end
    end
  end

  describe '#[]' do
    subject(:instance) { described_class.new(dummy_scrubber, dummy_normalizer, foo: 'bar') }

    context 'when key is a valid key' do
      it 'sets the value on the context' do
        expect(instance[:foo]).to eq 'bar'
      end
    end
    context 'when key has not been set' do
      it 'returns nil' do
        expect(instance[:baz]).to be nil
      end
    end
  end

  describe '#delete' do
    subject(:instance) { described_class.new(dummy_scrubber, dummy_normalizer, foo: 'bar') }

    context 'when key is a valid key' do
      it 'deletes the key' do
        expect(instance[:foo]).to eq 'bar'
        instance.delete(:foo)
        expect(instance[:foo]).to be nil
      end
    end
    context 'when key has not been set' do
      it 'returns nil' do
        instance.delete(:qux)
        expect(instance[:qux]).to be nil
      end
    end
  end

  describe '#clear' do
    subject(:instance) { described_class.new(dummy_scrubber, dummy_normalizer, foo: 'bar') }
    it 'clears the context' do
      expect(instance[:foo]).to eq 'bar'
      instance.clear
      expect(instance[:foo]).to be nil
    end
  end

  describe '#merge' do
    subject(:instance) { described_class.new(dummy_scrubber, dummy_normalizer, foo: 'bar') }
    it 'returns a merged hash of the context and the data' do
      expect(instance[:foo]).to eq 'bar'
      expect(instance.merge(baz: 'qux')).to include(foo: 'bar', baz: 'qux')
    end
  end

  describe '#merge' do
    subject(:instance) { described_class.new(dummy_scrubber, dummy_normalizer, foo: 'bar') }

    context 'with valid keys in the hash' do
      it 'updates the context with the merged data' do
        expect(instance[:foo]).to eq 'bar'
        # rubocop:disable Performance/RedundantMerge
        instance.merge!(baz: 'qux')
        # rubocop:enable Performance/RedundantMerge
        expect(instance.to_h).to include(foo: 'bar', baz: 'qux')
      end
    end

    context 'with existing, valid keys in the hash' do
      it 'updates the context with the merged data' do
        expect(instance[:foo]).to eq 'bar'
        # rubocop:disable Performance/RedundantMerge
        instance.merge!(foo: 'qux')
        # rubocop:enable Performance/RedundantMerge
        expect(instance.to_h).to include(foo: 'bar')
      end
    end

    context 'with reserved keys keys in the hash' do
      it 'raises an error' do
        expect(instance[:foo]).to eq 'bar'
        expect { instance.merge!(app: 'qux') }.to raise_error(::ArgumentError)
      end
    end
  end

  describe '#overwrite!' do
    subject(:instance) { described_class.new(dummy_scrubber, dummy_normalizer, foo: 'bar') }

    context 'with valid keys in the hash' do
      it 'replaces the context with new data, preserving keys that already exist' do
        expect(instance[:foo]).to eq 'bar'
        instance.overwrite!(foo: 'qux')
        expect(instance.to_h).to include(foo: 'qux')
      end
    end

    context 'with reserved keys keys in the hash' do
      it 'raises an error' do
        expect(instance[:foo]).to eq 'bar'
        expect { instance.overwrite!(app: 'qux') }.to raise_error(::ArgumentError)
      end
    end
  end

  describe '#scrub!' do
    subject(:instance) { described_class.new(dummy_scrubber, dummy_normalizer, foo: 'bar') }
    it 'scrubs the data' do
      expect(dummy_scrubber).to receive(:scrub).with(foo: 'bar')
      subject.scrub!
    end
  end

  describe '#normalize!' do
    subject(:instance) { described_class.new(dummy_scrubber, dummy_normalizer, foo: 'bar') }
    it 'normalizes the data' do
      expect(dummy_normalizer).to receive(:normalize).with(foo: 'bar')
      subject.normalize!
    end
  end

  describe 'to_h' do
    subject(:instance) { described_class.new(dummy_scrubber, dummy_normalizer, foo: 'bar') }
    it 'returns the data as a hash' do
      expect(instance.to_h).to include(foo: 'bar')
    end
  end
end

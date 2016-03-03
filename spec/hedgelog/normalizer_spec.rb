require 'spec_helper'
require 'hedgelog/normalizer'

describe Hedgelog::Normalizer do
  subject(:instance) { described_class.new }
  let(:struct_class) { Struct.new(:foo, :bar) }
  let(:struct) { struct_class.new(1234, 'dummy') }
  let(:hash) { {message: 'dummy=1234'} }
  let(:array) { ['dummy string', {message: 'dummy=1234'}] }
  describe '#normalize' do
    it 'returns the normalized data' do
      expect(instance.normalize(hash)).to include(message: 'dummy=1234')
    end

    it 'does not modify external state' do
      myvar = 'dummy=1234'
      orig_myvar = myvar.clone

      data = {foo: myvar}
      instance.normalize(data)
      expect(myvar).to eq orig_myvar
    end
  end
  describe '#normalize_hash' do
    it 'returns a normalized hash' do
      expect(instance.normalize_hash(hash)).to include(message: 'dummy=1234')
    end
  end
  describe '#normalize_struct' do
    it 'returns struct as a normalized hash' do
      expect(instance.normalize_struct(struct)).to include(foo: 1234, bar: 'dummy')
    end
  end
  describe '#normalize_array' do
    it 'returns array as a json string' do
      normalized_array = instance.normalize_array(array)
      expect(normalized_array).to be_a String
      expect(normalized_array).to eq '["dummy string",{"message":"dummy=1234"}]'
    end
  end
  context 'When a hash contains different types of data' do
    let(:data) { hash }
    before :each do
      # add other types to the hash
      data[:hash] = hash.clone
      data[:struct] = struct
      data[:array] = array
      data[:string] = 'dummy'
      data[:number] = 1234
    end
    it 'normalizes recursively' do
      result = instance.normalize_hash(data)
      expect(result[:hash]).to include(message: 'dummy=1234')
      expect(result[:message]).to include('dummy=1234')
      expect(result[:struct]).to be_a Hash
      expect(result[:struct]).to include(foo: 1234, bar: 'dummy')
      expect(result[:array]).to eq  '["dummy string",{"message":"dummy=1234"}]'
      expect(result[:string]).to eq 'dummy'
      expect(result[:number]).to eq 1234
    end
  end
end

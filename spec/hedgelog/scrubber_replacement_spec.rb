require 'spec_helper'
require 'hedgelog/scrub_replacement'

describe Hedgelog::ScrubReplacement do
  describe '#scrub_string' do
    subject { Hedgelog::ScrubReplacement.new(key, replacement).scrub_string(input) }
    let(:key) { 'password' }
    let(:replacement) { '*****' }
    let(:secret) { 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789~`!@\#$%^*()_+={}[]|:"\'<>.?/⚠️' }

    context 'the input looks like params' do
      let(:input) { "password=#{secret}&publicvar=foo" }
      it { should eq 'password=*****&publicvar=foo' }
    end

    context 'the input looks like a key value pair' do
      let(:input) { "password:#{secret};publicvar=foo" }
      it { should eq 'password:*****;publicvar=foo' }
    end

    context 'the input looks like a ruby hash' do
      let(:input) do
        {key => secret, 'publicvar' => 'foo'}.to_s
      end
      it { should eq '{"password"=>"*****", "publicvar"=>"foo"}' }
    end

    context 'the input looks like a key value pair in JSON' do
      let(:input) do
        {key => secret, 'publicvar' => 'foo'}.to_json
      end
      it { should eq '{"password":"*****","publicvar":"foo"}' }
    end

    context 'the input ends in a newline' do
      context 'the input looks like a key value pair' do
        let(:input) { "password:#{secret}\n" }
        it { should eq "password:*****\n" }
      end

      context 'the input looks like a key value pair' do
        let(:input) { "password:bar\n" }
        it { should eq "password:*****\n" }
      end

      context 'the input looks like a key value pair in JSON' do
        let(:input) { '{ "password": "bar" }\n' }
        it { should eq '{ "password": "*****" }\n' }
      end
    end

    context 'the input strings are embedded among other things' do
      context 'the input looks like params' do
        let(:input) { 'baz=foo&password=bar&one=two' }
        it { should eq 'baz=foo&password=*****&one=two' }
      end

      context 'the input looks like a key value pair' do
        let(:input) { '{ "foo": "bar", "password": "bar" }' }
        it { should eq '{ "foo": "bar", "password": "*****" }' }
      end
    end
  end

  describe '#scrub_hash' do
    subject { Hedgelog::ScrubReplacement.new(key, replacement).scrub_hash(input) }
    let(:key) { 'password' }
    let(:replacement) { '*****' }

    context 'the input has the key as a key of the hash' do
      let(:input) { {foo: 'bar', password: 'baz'} }

      it { should include(password: '*****') }
    end

    context 'the input has the key as a key of a nested hash' do
      let(:input) { {foo: 'bar', foo2: {password: 'baz'}} }

      it { should include(foo2: {password: '*****'}) }
    end

    context 'the input has the key in a string in the value of the hash' do
      let(:input) { {foo: 'bar', baz: 'password=mypass'} }

      it { should include(baz: 'password=*****') }
    end

    context 'the input has the key in a string nested in a value of the hash' do
      let(:input) { {foo: 'bar', foo2: {baz: 'password=mypass'}} }

      it { should include(foo2: {baz: 'password=*****'}) }
    end
  end

  describe '#scrub_array' do
    subject { Hedgelog::ScrubReplacement.new(key, replacement).scrub_array(input) }
    let(:key) { 'password' }
    let(:replacement) { '*****' }

    context 'the input has the key as a string value' do
      let(:input) { ['password=baz'] }

      it { should include('password=*****') }
    end

    context 'the input has the key in a nested string value' do
      let(:input) { [['password=baz'], 'bar'] }

      it { should include(['password=*****']) }
    end
  end
end

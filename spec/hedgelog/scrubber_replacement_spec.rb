require 'spec_helper'
require 'hedgelog/scrub_replacement'

describe Hedgelog::ScrubReplacement do
  describe '#scrub_string' do
    subject { Hedgelog::ScrubReplacement.new(key, replacement).scrub_string(input) }
    let(:key) { 'password' }
    let(:replacement) { '*****' }

    context 'the input looks like params' do
      let(:input) { 'password=bar' }
      it { should eq 'password=*****' }
    end

    context 'the input looks like a key value pair' do
      let(:input) { 'password:bar' }
      it { should eq 'password:*****' }
    end

    context 'the input looks like a key value pair in JSON' do
      let(:input) { '{ "password": "bar" }' }
      it { should eq '{ "password": "*****" }' }
    end

    context 'the input ends in a newline' do
      context 'the input looks like a key value pair' do
        let(:input) { "password:bar\n" }
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
end

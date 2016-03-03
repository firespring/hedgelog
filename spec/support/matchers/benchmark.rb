require 'rspec/expectations'
require 'benchmark/ips'

module Matchers
  module Benchmark
    extend RSpec::Matchers::DSL

    matcher :perform do
      match do |block_arg|
        report = ::Benchmark.ips(quiet: true) do |bm|
          bm.config(time: 5, warmup: 2)
          bm.report('first') { @second_block.call }
          bm.report('second') { block_arg.call }
        end

        @first_bm, @second_bm = *report.entries

        @first_bm.ips >= target_ips(@second_bm)
      end

      chain :times_slower do |slower|
        @slower = slower
      end

      chain :than do |&blk|
        @second_block = blk
      end

      failure_message do
        "expected function to perform #{target_ips(@second_bm)} IPS, but it only performed #{@first_bm.ips} IPS"
      end

      def target_ips(result)
        result.ips / (@slower || 1)
      end

      def supports_block_expectations?
        true
      end

      diffable
    end
  end
end

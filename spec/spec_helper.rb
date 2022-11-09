$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'pry'
require 'simplecov'
require 'hedgelog'

SimpleCov.minimum_coverage 99

Dir[File.expand_path(File.join(File.dirname(__FILE__), 'support', '**', '*.rb'))].sort.each { |f| require f }

RSpec.configure do |config|
  config.include Matchers::Benchmark
end

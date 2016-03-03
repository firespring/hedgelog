$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'pry'
require 'simplecov'
require 'hedgelog'

Dir[File.expand_path(File.join(File.dirname(__FILE__), 'support', '**', '*.rb'))].each { |f| require f }

SimpleCov.start

RSpec.configure do |config|
  config.include Matchers::Benchmark
end

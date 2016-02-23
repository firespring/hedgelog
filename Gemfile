source 'https://rubygems.org'

# Specify your gem's dependencies in hedgelog.gemspec
gemspec

group :test, :development do
  gem "rake", "~> 10.0"
  gem "rspec", "~> 3.3"
  gem "pry"
  gem "simplecov", "~> 0.10"
  gem "rubocop", "~> 0.33"
  gem "timecop"
  gem 'benchmark-ips'
end

group :development do
  gem 'ruby-prof'
  gem 'guard-rspec', require: false
end

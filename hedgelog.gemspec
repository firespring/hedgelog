lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hedgelog/version'

Gem::Specification.new do |spec|
  spec.name          = 'hedgelog'
  spec.version       = Hedgelog::VERSION
  spec.licenses      = ['MIT']
  spec.authors       = ['Jeff Utter']
  spec.email         = ['jeff.utter@firespring.com']

  spec.homepage      = 'https://github.com/firespring/hedgelog'
  spec.summary       = 'A strucutred JSON logger for Ruby'
  spec.description   = 'An opinionated/structured JSON logger for Ruby'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'yajl-ruby', '~> 1.4'
  spec.add_development_dependency 'bundler', '~> 2.0.1'
end

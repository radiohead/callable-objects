# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'callable/version'

Gem::Specification.new do |spec|
  spec.name          = 'callable-objects'
  spec.version       = Callable::VERSION
  spec.authors       = ['Igor Suleymanov']
  spec.email         = ['igorsuleymanoff@gmail.com']

  spec.summary       = %q{A collection of classes for building callable objects in Ruby.}
  spec.homepage      = 'https://github.com/radiohead/callable-objects'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ['lib']

  spec.add_dependency 'dry-types', '~> 0.11.0'
  spec.add_dependency 'dry-struct', '~> 0.3.1'
  spec.add_dependency 'dry-monads', '~> 0.3.1'

  spec.add_development_dependency 'bundler', '~> 1.15'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end

# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'acts-as-dag/version'

Gem::Specification.new do |spec|
  spec.name          = "acts-as-dag"
  spec.version       = ActsAsDag::VERSION
  spec.authors       = ["Kaid"]
  spec.email         = ["kaid@kaid.me"]
  spec.summary       = %q{Mongoid 有向无环图.}
  spec.description   = %q{Mongoid 有向无环图.}
  spec.homepage      = "https://github.com/mindpin/acts-as-dag"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "mongoid"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 2.3"
end

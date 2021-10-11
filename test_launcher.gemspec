# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'test_launcher/version'

Gem::Specification.new do |spec|
  spec.name          = "test_launcher"
  spec.version       = TestLauncher::VERSION
  spec.authors       = ["Pete Kinnecom"]
  spec.email         = ["pete.kinnecom@appfolio.com"]
  spec.summary       = %q{Easily run tests}
  spec.description   = %q{no really}
  spec.homepage      = "http://github.com/petekinnecom/test_launcher"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*.rb"] + ["test_launcher.gemspec", "bin/test_launcher", "LICENSE.txt"]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", ">= 1.7"
  spec.add_development_dependency "rake", ">= 12.3.3"
end

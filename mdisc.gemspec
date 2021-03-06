# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mdisc/version'

Gem::Specification.new do |spec|
  spec.name          = 'mdisc'
  spec.version       = Mdisc::VERSION
  spec.authors       = ['Rick Yu']
  spec.email         = ['cosmtrek@gmail.com']
  spec.summary       = %q{A local music player based on Netease music.}
  spec.description   = %q{}
  spec.homepage      = 'https://github.com/cosmtrek/mdisc'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_dependency 'curses', '~>1.0.1'
  spec.add_dependency 'open4', '~>1.3.4'
  spec.add_dependency 'unirest', '~>1.1.2'
end

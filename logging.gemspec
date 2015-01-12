Gem::Specification.new do |gem|
  gem.name          = 'logging'
  gem.version       = File.read(File.expand_path('../version.txt', __FILE__)).strip
  gem.authors       = ['Tim Pease']
  gem.email         = ['tim.pease@gmail.com']
  gem.description   = %q{Logging is a flexible logging library for use in Ruby programs based on the design of Java's log4j library. It features a hierarchical logging system, custom level names, multiple output destinations per log event, custom formatting, and more.} #'
  gem.summary       = %q{A flexible and extendable logging library for Ruby}
  gem.homepage      = 'http://rubygems.org/gems/logging'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']
  gem.add_dependency 'little-plugger'
  gem.add_dependency 'multi_json'
  gem.add_development_dependency 'flexmock', '~> 1.0'
  gem.add_development_dependency 'bones-git'
end

# -*- encoding: utf-8 -*-
#$:.push File.expand_path("../lib", __FILE__)
#require 'logging/version'

# Removed dependency on rake because of error when running `bundle install --deployment`
#   There was a LoadError while evaluating log4r.gemspec:
#     no such file to load -- rake from
#     vendor/bundle/ruby/1.8/bundler/gems/log4r/log4r.gemspec:3

Gem::Specification.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "logging"
  gem.version = '1.8.2'
  gem.summary = %Q{logging, logging framework for ruby}
  gem.description = %Q{See also: http://logging.rubyforge.org}
  gem.email = "tim.pease@gmail.com"
  gem.homepage = "http://logging.rubyforge.org"
  gem.authors = ['time pease', 'tony kerz']
  #gem.bindir = 'bin'
  #gem.test_files = Dir.glob("tests/**/*")
  gem.files = Dir['lib/**/*']

  gem.add_development_dependency "bundler", [">= 1.0.0"]
  gem.add_development_dependency 'rake', ["~> 0.8.7"]
end
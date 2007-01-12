
ENV['RUBY_FLAGS'] ||= "-I#{%w(lib test).join(File::PATH_SEPARATOR)}"

require 'rubygems'
require 'hoe'

PKG_VERSION = ENV['VERSION'] || '0.0.0'

Hoe.new('logging', PKG_VERSION) do |proj|
  proj.rubyforge_name = 'logging'
  proj.author = 'Tim Pease'
  proj.email = 'tim.pease@gmail.com'
  proj.url = 'http://logging.rubyforge.org/'
  proj.extra_deps = []
  proj.clean_globs << 'coverage'
  proj.summary = 'A flexible and extendable logging library for Ruby.'
  proj.description = <<-DESC
Logging is a flexible logging library for use in Ruby programs based on the
design of Java's log4j library. It features a hierarchical logging system,
custom level names, multiple output destinations per log event, custom
formatting, and more.
  DESC
  proj.changes = <<-CHANGES
Version 0.1.0 / 2007-01-12
  * initial release
  CHANGES
end

# --------------------------------------------------------------------------
desc 'Run rcov on the unit tests'
task :coverage do
  opts = "-x turn\\\\.rb\\\\z -T --sort coverage --no-html"
  sh "rcov -Ilib test/test_all.rb #{opts}"
end

# EOF

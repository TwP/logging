# $Id: Rakefile 76 2007-01-09 17:51:45Z tpease $

require 'rubygems'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'rake/contrib/sshpublisher'


PKG = 'logging'
PKG_VERSION = ENV['VERSION'] || '0.0.0'
PKG_FILES = FileList['lib/**/*.rb', 'test/*.rb', 'README.txt']
TEST_FILE = 'test/tests.rb'

PUB_HOST = 'root@pong'
PUB_DIR  = '/var/www/html/sts.ball.com/gems'


task :default => [:test]

# ----------------------------------------------------------------------------
desc 'Run unit tests'
task :test do
  ruby "-Ilib #{TEST_FILE}"
end

# ----------------------------------------------------------------------------
desc 'Run rcov on the unit tests'
task :coverage do
  opts = "-x turn\\\\.rb\\\\z -T --sort coverage --no-html"
  sh "rcov -Ilib #{TEST_FILE} #{opts}"
end

# ----------------------------------------------------------------------------
desc 'Run benchmark tests'
task :benchmark do
  ruby '-Ilib test/benchmark.rb'
end

# ----------------------------------------------------------------------------
desc 'Remove the coverage results'
task :clobber_coverage do
  rm_r 'coverage' rescue nil
end
task :clobber => [:clobber_coverage]

# ----------------------------------------------------------------------------
desc 'Publish to the gem server (needs VERSION)'
task :publish => [:test, :package] do
  Rake::SshFilePublisher.new(
    PUB_HOST, File.join(PUB_DIR, 'gems'),
    'pkg', "#{PKG}-#{PKG_VERSION}.gem"
  ).upload

  sh "ssh #{PUB_HOST} \"" +
       "cd #{PUB_DIR}; " +
       "index_gem_repository.rb; " +
       "chown -R apache:apache *\""
end

# ----------------------------------------------------------------------------
Rake::RDocTask.new do |rd|
  rd.title = 'Logging'
  rd.main = 'README.txt'
  rd.rdoc_files.include 'README.txt', 'lib/**/*.rb'
  rd.rdoc_dir = 'rdoc'
end

# ----------------------------------------------------------------------------
spec = Gem::Specification.new do |s|
  s.name     = PKG
  s.summary  = 'Flexible/Extensible Logging Framework'
  s.version  = PKG_VERSION
  s.author   = 'Tim Pease'
  s.email    = 'tim.pease@gmail.com'
  s.platform = Gem::Platform::RUBY
  s.files    = PKG_FILES

  s.require_path     = 'lib'
  s.test_file        = TEST_FILE
  s.has_rdoc         = true
  s.extra_rdoc_files = ['README.txt']
  s.rdoc_options  << '--title' << 'Ruby Logging Framework' <<
                     '--main' << 'README.txt'
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

# EOF

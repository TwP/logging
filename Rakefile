# $Id$

load 'tasks/setup.rb'

ensure_in_path 'lib'
require 'logging'

task :default => 'test:run'

PROJ.name = 'logging'
PROJ.summary = 'A flexible and extendable logging library for Ruby'
PROJ.authors = 'Tim Pease'
PROJ.email = 'tim.pease@gmail.com'
PROJ.url = 'http://logging.rubyforge.org/'
PROJ.rubyforge_name = 'logging'
PROJ.rdoc_dir = 'doc/rdoc'
#PROJ.rdoc_remote_dir = 'rdoc'
PROJ.rdoc_remote_dir = ''
PROJ.version = Logging::VERSION

PROJ.exclude += %w[^tags$ ^tasks/archive ^coverage]
PROJ.rdoc_exclude << '^data'
PROJ.svn = true

depend_on 'flexmock'

# EOF

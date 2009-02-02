
begin
  require 'bones'
  Bones.setup
rescue LoadError
  begin
    load 'tasks/setup.rb'
  rescue LoadError
    raise RuntimeError, '### please install the "bones" gem ###'
  end
end

ensure_in_path 'lib'
require 'logging'

task :default => 'test:run'

PROJ.name = 'logging'
PROJ.summary = 'A flexible and extendable logging library for Ruby'
PROJ.authors = 'Tim Pease'
PROJ.email = 'tim.pease@gmail.com'
PROJ.url = 'http://logging.rubyforge.org/'
PROJ.rubyforge.name = 'logging'
PROJ.version = Logging::VERSION
PROJ.readme_file = 'README.rdoc'
PROJ.ignore_file = '.gitignore'

PROJ.exclude << %w[^tags$]
PROJ.rdoc.exclude << '^data'
#PROJ.rdoc.dir = 'doc/rdoc'
#PROJ.rdoc.remote_dir = 'rdoc'
PROJ.rdoc.dir = 'doc'
PROJ.rdoc.remote_dir = ''

PROJ.ann.email[:server] = 'smtp.gmail.com'
PROJ.ann.email[:port] = 587
PROJ.ann.email[:from] = 'Tim Pease'

depend_on 'flexmock'
depend_on 'lockfile'

# EOF

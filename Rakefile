
begin
  require 'bones'
rescue LoadError
  abort '### please install the "bones" gem ###'
end

ensure_in_path 'lib'
require 'logging'

task :default => 'test:run'
task 'gem:release' => 'test:run'

Bones {
  name         'logging'
  summary      'A flexible and extendable logging library for Ruby'
  authors      'Tim Pease'
  email        'tim.pease@gmail.com'
  url          'http://gemcutter.org/gems/logging'
  version      Logging::VERSION
  readme_file  'README.rdoc'
  ignore_file  '.gitignore'

  rdoc.exclude << '^data'
  rdoc.include << '^examples/.*\.rb'
  #rdoc.dir = 'doc/rdoc'

  use_gmail
  enable_sudo

  depend_on 'little-plugger'
  depend_on 'lockfile'
  depend_on 'flexmock',     :development => true
  depend_on 'bones-git',    :development => true
  depend_on 'bones-extras', :development => true
}


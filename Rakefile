
begin
  require 'bones'
rescue LoadError
  abort '### please install the "bones" gem ###'
end

task :default => 'test:run'
task 'gem:release' => 'test:run'

Bones {
  name         'logging'
  summary      'A flexible and extendable logging library for Ruby'
  authors      'Tim Pease'
  email        'tim.pease@gmail.com'
  url          'http://rubygems.org/gems/logging'
  readme_file  'README.rdoc'
  ignore_file  '.gitignore'

  rdoc.exclude << '^data'
  rdoc.include << '^examples/.*\.rb'
  #rdoc.dir = 'doc/rdoc'

  use_gmail

  depend_on 'little-plugger'

  depend_on 'flexmock',     :development => true
  depend_on 'bones-git',    :development => true
  depend_on 'bones-extras', :development => true
}


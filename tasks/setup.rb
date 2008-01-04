# $Id$

require 'rubygems'
require 'rake'
require 'fileutils'
require 'ostruct'

PROJ = OpenStruct.new

PROJ.name = nil
PROJ.summary = nil
PROJ.description = nil
PROJ.changes = nil
PROJ.authors = nil
PROJ.email = nil
PROJ.url = nil
PROJ.version = ENV['VERSION'] || '0.0.0'
PROJ.rubyforge_name = nil
PROJ.exclude = %w(tmp$ bak$ ~$ CVS .svn/ ^pkg/ ^doc/)

# Rspec
PROJ.specs = FileList['spec/**/*_spec.rb']
PROJ.spec_opts = []

# Test::Unit
PROJ.tests = FileList['test/**/test_*.rb']
PROJ.test_file = 'test/all.rb'
PROJ.test_opts = []

# Rcov
PROJ.rcov_opts = ['--sort', 'coverage', '-T']

# Rdoc
PROJ.rdoc_opts = []
PROJ.rdoc_include = %w(^lib/ ^bin/ ^ext/ .txt$)
PROJ.rdoc_exclude = %w(extconf.rb$ ^Manifest.txt$)
PROJ.rdoc_main = 'README.txt'
PROJ.rdoc_dir = 'doc'
PROJ.rdoc_remote_dir = nil

# Extensions
PROJ.extensions = FileList['ext/**/extconf.rb']
PROJ.ruby_opts = %w(-w)
PROJ.libs = []
%w(lib ext).each {|dir| PROJ.libs << dir if test ?d, dir}

# Gem Packaging
PROJ.files =
  if test ?f, 'Manifest.txt'
    files = File.readlines('Manifest.txt').map {|fn| fn.chomp.strip}
    files.delete ''
    files
  else [] end
PROJ.executables = PROJ.files.find_all {|fn| fn =~ %r/^bin/}
PROJ.dependencies = []
PROJ.need_tar = true
PROJ.need_zip = false

# File Annotations
PROJ.annotation_exclude = []
PROJ.annotation_extensions = %w(.txt .rb .erb) << ''

# Subversion Repository
PROJ.svn = false
PROJ.svn_root = nil
PROJ.svn_trunk = 'trunk'
PROJ.svn_tags = 'tags'
PROJ.svn_branches = 'branches'

# Load the other rake files in the tasks folder
Dir.glob('tasks/*.rake').sort.each {|fn| import fn}

# Setup some constants
WIN32 = %r/win32/ =~ RUBY_PLATFORM unless defined? WIN32

DEV_NULL = WIN32 ? 'NUL:' : '/dev/null'

def quiet( &block )
  io = [STDOUT.dup, STDERR.dup]
  STDOUT.reopen DEV_NULL
  STDERR.reopen DEV_NULL
  block.call
ensure
  STDOUT.reopen io.first
  STDERR.reopen io.last
end

DIFF = if WIN32 then 'diff.exe'
       else
         if quiet {system "gdiff", __FILE__, __FILE__} then 'gdiff'
         else 'diff' end
       end unless defined? DIFF

SUDO = if WIN32 then ''
       else
         if quiet {system 'which sudo'} then 'sudo'
         else '' end
       end

RCOV = WIN32 ? 'rcov.cmd'  : 'rcov'
GEM  = WIN32 ? 'gem.cmd'   : 'gem'

%w(rcov spec/rake/spectask rubyforge bones).each do |lib|
  begin
    require lib
    Object.instance_eval {const_set "HAVE_#{lib.tr('/','_').upcase}", true}
  rescue LoadError
    Object.instance_eval {const_set "HAVE_#{lib.tr('/','_').upcase}", false}
  end
end

# Reads a file at +path+ and spits out an array of the +paragraphs+
# specified.
#
#    changes = paragraphs_of('History.txt', 0..1).join("\n\n")
#    summary, *description = paragraphs_of('README.txt', 3, 3..8)
#
def paragraphs_of(path, *paragraphs)
  File.read(path).delete("\r").split(/\n\n+/).values_at(*paragraphs)
end

# Adds the given gem _name_ to the current project's dependency list. An
# optional gem _version_ can be given. If omitted, the newest gem version
# will be used.
#
def depend_on( name, version = nil )
  spec = Gem.source_index.find_name(name).last
  version = spec.version.to_s if version.nil? and !spec.nil?

  PROJ.dependencies << (version.nil? ? [name] : [name, ">= #{version}"])
end

# Adds the given _path_ to the include path if it is not already there
#
def ensure_in_path( path )
  path = File.expand_path(path)
  $:.unshift(path) if test(?d, path) and not $:.include?(path)
end

# Find a rake task using the task name and remove any description text. This
# will prevent the task from being displayed in the list of available tasks.
#
def remove_desc_for_task( names )
  Array(names).each do |task_name|
    task = Rake.application.tasks.find {|t| t.name == task_name}
    next if task.nil?
    task.instance_variable_set :@comment, nil
  end
end

# EOF

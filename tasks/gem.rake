# $Id$

require 'rake/gempackagetask'

namespace :gem do

  PROJ.spec = Gem::Specification.new do |s|
    s.name = PROJ.name
    s.version = PROJ.version
    s.summary = PROJ.summary
    s.authors = Array(PROJ.authors)
    s.email = PROJ.email
    s.homepage = Array(PROJ.url).first
    s.rubyforge_project = PROJ.rubyforge_name

    s.description = PROJ.description

    PROJ.dependencies.each do |dep|
      s.add_dependency(*dep)
    end

    s.files = PROJ.files
    s.executables = PROJ.executables.map {|fn| File.basename(fn)}
    s.extensions = PROJ.files.grep %r/extconf\.rb$/

    s.bindir = 'bin'
    dirs = Dir["{#{PROJ.libs.join(',')}}"]
    s.require_paths = dirs unless dirs.empty?

    incl = Regexp.new(PROJ.rdoc_include.join('|'))
    excl = PROJ.rdoc_exclude.dup.concat %w[\.rb$ ^(\.\/|\/)?ext]
    excl = Regexp.new(excl.join('|'))
    rdoc_files = PROJ.files.find_all do |fn|
                   case fn
                   when excl; false
                   when incl; true
                   else false end
                 end
    s.rdoc_options = PROJ.rdoc_opts + ['--main', PROJ.rdoc_main]
    s.extra_rdoc_files = rdoc_files
    s.has_rdoc = true

    if test ?f, PROJ.test_file
      s.test_file = PROJ.test_file
    else
      s.test_files = PROJ.tests.to_a
    end

    # Do any extra stuff the user wants
#   spec_extras.each do |msg, val|
#     case val
#     when Proc
#       val.call(s.send(msg))
#     else
#       s.send "#{msg}=", val
#     end
#   end
  end

  desc 'Show information about the gem'
  task :debug do
    puts PROJ.spec.to_ruby
  end

  Rake::GemPackageTask.new(PROJ.spec) do |pkg|
    pkg.need_tar = PROJ.need_tar
    pkg.need_zip = PROJ.need_zip
  end

  desc 'Install the gem'
  task :install => [:clobber, :package] do
    sh "#{SUDO} #{GEM} install pkg/#{PROJ.spec.file_name}"
  end

  desc 'Uninstall the gem'
  task :uninstall do
    sh "#{SUDO} #{GEM} uninstall -v '#{PROJ.version}' #{PROJ.name}"
  end

end  # namespace :gem

desc 'Alias to gem:package'
task :gem => 'gem:package'

task :clobber => 'gem:clobber_package'

remove_desc_for_task %w(gem:clobber_package)

# EOF

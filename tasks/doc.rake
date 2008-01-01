# $Id$

require 'rake/rdoctask'

namespace :doc do

  desc 'Generate RDoc documentation'
  Rake::RDocTask.new do |rd|
    rd.main = PROJ.rdoc_main
    rd.options << '-d' if !WIN32 and `which dot` =~ %r/\/dot/
    rd.rdoc_dir = PROJ.rdoc_dir

    incl = Regexp.new(PROJ.rdoc_include.join('|'))
    excl = Regexp.new(PROJ.rdoc_exclude.join('|'))
    files = PROJ.files.find_all do |fn|
              case fn
              when excl; false
              when incl; true
              else false end
            end
    rd.rdoc_files.push(*files)

    title = "#{PROJ.name}-#{PROJ.version} Documentation"
    title = "#{PROJ.rubyforge_name}'s " + title if PROJ.rubyforge_name != title

    rd.options << "-t #{title}"
  end

  desc 'Generate ri locally for testing'
  task :ri => :clobber_ri do
    sh "#{RDOC} --ri -o ri ."
  end

  desc 'Remove ri products'
  task :clobber_ri do
    rm_r 'ri' rescue nil
  end

end  # namespace :doc

desc 'Alias to doc:rdoc'
task :doc => 'doc:rdoc'

desc 'Remove all build products'
task :clobber => %w(doc:clobber_rdoc doc:clobber_ri)

remove_desc_for_task %w(doc:clobber_rdoc doc:clobber_ri)

# EOF

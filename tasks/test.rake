# $Id$

require 'rake/testtask'

namespace :test do

  Rake::TestTask.new(:run) do |t|
    t.libs = PROJ.libs
    t.test_files = if test(?f, PROJ.test_file) then [PROJ.test_file]
                   else PROJ.tests end
    t.ruby_opts += PROJ.ruby_opts
    t.ruby_opts += PROJ.test_opts
  end

  if HAVE_RCOV
    desc 'Run rcov on the unit tests'
    task :rcov => :clobber_rcov do
      opts = PROJ.rcov_opts.dup << '-o' << PROJ.rcov_dir
      opts = opts.join(' ')
      files = if test(?f, PROJ.test_file) then [PROJ.test_file]
              else PROJ.tests end
      files = files.join(' ')
      sh "#{RCOV} #{files} #{opts}"
    end

    task :clobber_rcov do
      rm_r 'coverage' rescue nil
    end
  end

end  # namespace :test

desc 'Alias to test:run'
task :test => 'test:run'

task :clobber => 'test:clobber_rcov' if HAVE_RCOV

# EOF

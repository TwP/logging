# $Id: spec.rake 13 2007-08-23 22:18:00Z tim_pease $

if HAVE_SPEC

require 'spec/rake/spectask'

namespace :spec do

  desc 'Run all specs with basic output'
  Spec::Rake::SpecTask.new(:run) do |t|
    t.spec_opts = PROJ.spec_opts
    t.spec_files = PROJ.specs
  end

  desc 'Run all specs with text output'
  Spec::Rake::SpecTask.new(:specdoc) do |t|
    t.spec_opts = PROJ.spec_opts + ['--format', 'specdoc']
    t.spec_files = PROJ.specs
  end

  if HAVE_RCOV
    desc 'Run all specs with RCov'
    Spec::Rake::SpecTask.new(:rcov) do |t|
      t.spec_opts = PROJ.spec_opts
      t.spec_files = PROJ.specs
      t.rcov = true
      t.rcov_opts = PROJ.rcov_opts + ['--exclude', 'spec']
    end
  end

end  # namespace :spec

task :clobber => 'spec:clobber_rcov' if HAVE_RCOV

end  # if HAVE_SPEC

# EOF

# $Id: website.rake 12 2007-08-23 16:43:11Z tim_pease $

namespace :website do

  desc 'Build the Logging website'
  task :build do
    begin
      olddir = pwd
      chdir 'website'
      sh 'rake build'
      cp_r 'output/.', olddir + '/doc'
    ensure
      chdir olddir
    end
  end

  desc 'Remove the Logging website'
  task :clobber do
    rm_r 'doc' rescue nil
  end

  desc 'Publish the website to RubyForge'
  task :release => %w(website:clobber doc:rdoc website:build) do
    config = YAML.load(
        File.read(File.expand_path('~/.rubyforge/user-config.yml'))
    )

    host = "#{config['username']}@rubyforge.org"
    remote_dir = "/var/www/gforge-projects/#{PROJ.rubyforge_name}/"

    sh "rsync --delete -rulptzCF doc/ #{host}:#{remote_dir}"
  end

end  # namespace :website

task :clobber => 'website:clobber'

# EOF

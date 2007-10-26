# $Id: manifest.rake 11 2007-08-23 15:45:16Z tim_pease $

require 'find'

namespace :manifest do

  desc 'Verify the manfiest'
  task :check do
    fn = 'Manifest.tmp'
    files = []
    exclude = Regexp.new(PROJ.exclude.join('|'))
    Find.find '.' do |path|
      next unless test ?f, path
      next if path =~ exclude
      files << path[2..-1]
    end

    File.open(fn, 'w') {|fp| fp.puts files.sort}
    system "#{DIFF} -du Manifest.txt #{fn}"
    rm fn rescue nil
  end

  desc 'Create a new manifest'
  task :create do
    fn = 'Manifest.txt'
    files = []
    exclude = Regexp.new(PROJ.exclude.join('|'))
    Find.find '.' do |path|
      next unless test ?f, path
      next if path =~ exclude
      files << path[2..-1]
    end

    files << fn unless test ?f, fn
    File.open(fn, 'w') {|fp| fp.puts files.sort}
  end
end

# EOF

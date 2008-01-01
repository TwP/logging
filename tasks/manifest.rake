# $Id$

require 'find'

namespace :manifest do

  desc 'Verify the manifest'
  task :check do
    fn = 'Manifest.tmp'
    files = []
    exclude = Regexp.new(PROJ.exclude.join('|'))
    Find.find '.' do |path|
      path.sub! %r/^(\.\/|\/)/o, ''
      next unless test ?f, path
      next if path =~ exclude
      files << path
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
      path.sub! %r/^(\.\/|\/)/o, ''
      next unless test ?f, path
      next if path =~ exclude
      files << path
    end

    files << fn unless test ?f, fn
    File.open(fn, 'w') {|fp| fp.puts files.sort}
  end
end

# EOF

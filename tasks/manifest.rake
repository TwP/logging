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
    lines = %x(#{DIFF} -du Manifest.txt #{fn}).split("\n")
    if HAVE_FACETS_ANSICODE and ENV.has_key?('TERM')
      lines.map! do |line|
        case line
        when %r/^(-{3}|\+{3})/; nil
        when %r/^@/; Console::ANSICode.blue line
        when %r/^\+/; Console::ANSICode.green line
        when %r/^\-/; Console::ANSICode.red line
        else line end
      end
    end
    puts lines.compact
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
end  # namespace :manifest

desc 'Alias to manifest:check'
task :manifest => 'manifest:check'

# EOF

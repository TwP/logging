# $Id$

require 'find'

namespace :manifest do

  desc 'Verify the manifest'
  task :check do
    fn = 'Manifest.tmp'
    files = manifest_files

    File.open(fn, 'w') {|fp| fp.puts files}
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
    files = manifest_files
    unless test(?f, fn)
      files << fn
      files.sort!
    end
    File.open(fn, 'w') {|fp| fp.puts files}
  end

  task :assert do
    files = manifest_files
    manifest = File.read('Manifest.txt').split($/)
    raise RuntimeError, "Manifest.txt is out of date" unless files == manifest
  end

end  # namespace :manifest

desc 'Alias to manifest:check'
task :manifest => 'manifest:check'

# EOF

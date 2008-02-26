# $Id$

require 'find'

namespace :manifest do

  desc 'Verify the manifest'
  task :check do
    fn = PROJ.manifest_file + '.tmp'
    files = manifest_files

    File.open(fn, 'w') {|fp| fp.puts files}
    lines = %x(#{DIFF} -du #{PROJ.manifest_file} #{fn}).split("\n")
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
    files = manifest_files
    unless test(?f, PROJ.manifest_file)
      files << PROJ.manifest_file
      files.sort!
    end
    File.open(PROJ.manifest_file, 'w') {|fp| fp.puts files}
  end

  task :assert do
    files = manifest_files
    manifest = File.read(PROJ.manifest_file).split($/)
    raise "ERROR: #{PROJ.manifest_file} is out of date" unless files == manifest
  end

end  # namespace :manifest

desc 'Alias to manifest:check'
task :manifest => 'manifest:check'

# EOF

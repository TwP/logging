# $Id$


if PROJ.svn and system("svn --version 2>&1 > #{DEV_NULL}")

unless PROJ.svn_root
  info = %x/svn info ./
  m = %r/^Repository Root:\s+(.*)$/.match(info)
  PROJ.svn_root = (m.nil? ? '' : m[1])
end
PROJ.svn_root = File.join(PROJ.svn_root, PROJ.svn) if String === PROJ.svn

namespace :svn do

  desc 'Show tags from the SVN repository'
  task :show_tags do |t|
    tags = %x/svn list #{File.join(PROJ.svn_root, PROJ.svn_tags)}/
    tags.gsub!(%r/\/$/, '')
    puts tags
  end

  desc 'Create a new tag in the SVN repository'
  task :create_tag do |t|
    v = ENV['VERSION'] or abort 'Must supply VERSION=x.y.z'
    abort "Versions don't match #{v} vs #{PROJ.version}" if v != PROJ.version

    trunk = File.join(PROJ.svn_root, PROJ.svn_trunk)
    tag = "%s-%s" % [PROJ.name, PROJ.version]
    tag = File.join(PROJ.svn_root, PROJ.svn_tags, tag)
    msg = "Creating tag for #{PROJ.name} version #{PROJ.version}"

    puts "Creating SVN tag '#{tag}'"
    unless system "svn cp -m '#{msg}' #{trunk} #{tag}"
      abort "Tag creation failed" 
    end
  end

end  # namespace :svn

task 'gem:release' => 'svn:create_tag'

end  # if PROJ.svn

# EOF

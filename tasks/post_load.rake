# $Id$

# This file does not define any rake tasks. It is used to load some project
# settings if they are not defined by the user.

PROJ.rdoc_exclude << "^#{Regexp.escape(PROJ.manifest_file)}$"
PROJ.exclude << "^#{Regexp.escape(PROJ.ann_file)}$"

PROJ.exclude.flatten!
PROJ.rdoc_exclude.flatten!
PROJ.annotation_exclude.flatten!

PROJ.changes ||= paragraphs_of(PROJ.history_file, 0..1).join("\n\n")

PROJ.description ||= paragraphs_of(PROJ.readme_file, 'description').join("\n\n")

PROJ.summary ||= PROJ.description.split('.').first

PROJ.files ||=
  if test(?f, PROJ.manifest_file)
    files = File.readlines(PROJ.manifest_file).map {|fn| fn.chomp.strip}
    files.delete ''
    files
  else [] end

PROJ.executables ||= PROJ.files.find_all {|fn| fn =~ %r/^bin/}

PROJ.rdoc_main ||= PROJ.readme_file

# EOF

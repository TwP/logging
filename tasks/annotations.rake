# $Id$

if HAVE_BONES

desc "Enumerate all annotations"
task :notes do
  Bones::AnnotationExtractor.enumerate "OPTIMIZE|FIXME|TODO", :tag => true
end

namespace :notes do
  desc "Enumerate all OPTIMIZE annotations"
  task :optimize do
    Bones::AnnotationExtractor.enumerate "OPTIMIZE"
  end

  desc "Enumerate all FIXME annotations"
  task :fixme do
    Bones::AnnotationExtractor.enumerate "FIXME"
  end

  desc "Enumerate all TODO annotations"
  task :todo do
    Bones::AnnotationExtractor.enumerate "TODO"
  end
end

end  # if HAVE_BONES

# EOF

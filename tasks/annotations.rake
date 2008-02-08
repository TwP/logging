# $Id$

if HAVE_BONES

desc "Enumerate all annotations"
task :notes do
  Bones::AnnotationExtractor.enumerate(
      PROJ, PROJ.annotation_tags.join('|'), :tag => true)
end

namespace :notes do
  PROJ.annotation_tags.each do |tag|
    desc "Enumerate all #{tag} annotations"
    task tag.downcase.to_sym do
      Bones::AnnotationExtractor.enumerate(PROJ, tag)
    end
  end
end

end  # if HAVE_BONES

# EOF

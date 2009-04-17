
module Logging
  module Layouts

    def basic( *args )
      return ::Logging::Layouts::Basic if args.empty?
      ::Logging::Layouts::Basic.new(*args)
    end

    def pattern( *args )
      return ::Logging::Layouts::Pattern if args.empty?
      ::Logging::Layouts::Pattern.new(*args)
    end

    def parseable
      ::Logging::Layouts::Parseable
    end

    def json( *args )
      ::Logging::Layouts::Parseable.json(*args)
    end

    def yaml( *args )
      ::Logging::Layouts::Parseable.yaml(*args)
    end

    extend self
  end  # module Layouts
end  # module Logging


%w[basic parseable pattern].
each do |fn|
  require ::Logging.libpath('logging', 'layouts', fn)
end

# EOF

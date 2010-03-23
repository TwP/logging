
module Logging
  module Layouts

    # Accessor / Factory for the Basic layout.
    #
    def basic( *args )
      return ::Logging::Layouts::Basic if args.empty?
      ::Logging::Layouts::Basic.new(*args)
    end

    # Accessor / Factory for the Pattern layout.
    #
    def pattern( *args )
      return ::Logging::Layouts::Pattern if args.empty?
      ::Logging::Layouts::Pattern.new(*args)
    end

    # Accessor for the Parseable layout.
    #
    def parseable
      ::Logging::Layouts::Parseable
    end

    # Factory for the Parseable layout using JSON formatting.
    #
    def json( *args )
      ::Logging::Layouts::Parseable.json(*args)
    end

    # Factory for the Parseable layout using YAML formatting.
    #
    def yaml( *args )
      ::Logging::Layouts::Parseable.yaml(*args)
    end

    extend self
  end  # module Layouts
end  # module Logging

Logging.libpath {
  require 'logging/layouts/basic'
  require 'logging/layouts/parseable'
  require 'logging/layouts/pattern'
}

# EOF

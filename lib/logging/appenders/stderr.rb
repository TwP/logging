module Logging::Appenders

  # This class provides an Appender that can write to STDERR.
  #
  class Stderr < ::Logging::Appenders::IO

    # call-seq:
    #    Stderr.new( name = 'stderr' )
    #    Stderr.new( :layout => layout )
    #    Stderr.new( name = 'stderr', :level => 'warn' )
    #
    # Creates a new Stderr Appender. The name 'stderr' will be used unless
    # another is given. Optionally, a layout can be given for the appender
    # to use (otherwise a basic appender will be created) and a log level
    # can be specified.
    #
    # Options:
    #
    #    :layout   => the layout to use when formatting log events
    #    :level    => the level at which to log
    #
    def initialize( *args )
      opts = Hash === args.last ? args.pop : {}
      name = args.empty? ? 'stderr' : args.shift

      opts[:encoding] = STDERR.external_encoding if STDERR.respond_to? :external_encoding

      super(name, STDERR, opts)
    end
  end  # Stderr
end  # Logging::Appenders

module Logging::Appenders

  # This class provides an Appender that can write to STDOUT.
  #
  class Stdout < ::Logging::Appenders::IO

    # call-seq:
    #    Stdout.new( name = 'stdout' )
    #    Stdout.new( :layout => layout )
    #    Stdout.new( name = 'stdout', :level => 'info' )
    #
    # Creates a new Stdout Appender. The name 'stdout' will be used unless
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
      name = args.empty? ? 'stdout' : args.shift

      opts[:encoding] = STDOUT.external_encoding if STDOUT.respond_to? :external_encoding

      super(name, STDOUT, opts)
    end
  end  # Stdout

end  # Logging::Appenders

# $Id$

require 'logging/appender'

module Logging
module Appenders

  #
  # This class provides an Appender that can write to any IO stream
  # configured for writing.
  #
  class IO < ::Logging::Appender

    #
    # call-seq:
    #    IO.new( name, io )
    #    IO.new( name, io, :layout => layout )
    #
    # Creates a new IO Appender using the given name that will use the _io_
    # stream as the logging destination.
    #
    def initialize( name, io, opts = {} )
      unless io.respond_to? :print
        raise TypeError, "expecting an IO object but got '#{io.class.name}'"
      end

      @io = io
      @io.sync = true

      super(name, opts)
    end

    #
    # call-seq:
    #    close( footer = true )
    #
    # Close the appender and writes the layout footer to the logging
    # destination if the _footer_ flag is set to +true+. Log events will
    # no longer be written to the logging destination after the appender
    # is closed.
    #
    def close( *args )
      return self if @io.nil?
      sync do
        super *args
        @io.close unless [STDIN, STDERR, STDOUT].include?(@io)
        @io = nil
      end
      self
    end

    #
    # call-seq:
    #    flush
    #
    # Call +flush+ to force an appender to write out any buffered log events.
    # Similar to IO#flush, so use in a similar fashion.
    #
    def flush
      return self if @io.nil?
      @io.flush
      self
    end


    private
    #
    # call-seq:
    #    write( str )
    #
    # Writes the given string to the IO stream. If an +IOError+ is detected,
    # than this appender will be closed and the error reported.
    #
    def write( str )
      begin
        @io.print str
      rescue IOError
        close false
        raise
      end
    end

  end  # class IO
end  # module Appenders
end  # module Logging

# EOF


require 'stringio'

module Logging::Appenders

  # This class provides an Appender that can write to a StringIO instance.
  # This is very useful for testing log message output.
  #
  class StringIo < ::Logging::Appenders::IO

    # The StringIO instance the appender is writing to.
    attr_reader :sio

    # call-seq:
    #    StringIo.new( name, opts = {} )
    #
    # Creates a new StrinIo appender that will append log messages to a
    # StringIO instance.
    #
    def initialize( name, opts = {} )
      @sio = StringIO.new
      super(name, @sio, opts)
      clear
    end

    # Read a single line of text from the internal StringIO instance. +nil+
    # is returned if the StringIO buffer is empty.
    #
    def readline
      sync {
        begin
          @sio.seek @pos
          line = @sio.readline
          @pos = @sio.tell
          line
        rescue EOFError
          nil
        end
      }
    end

    # Clears the internal StringIO instance. All log messages are removed
    # from the buffer.
    #
    def clear
      sync {
        @pos = 0
        @sio.seek 0
        @sio.truncate 0
      }
    end
    alias :reset :clear

  end  # class StringIo
end  # module Logging::Appenders

# EOF

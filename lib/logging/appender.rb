# $Id$

require 'sync'
require 'logging/logger'
require 'logging/layout'
require 'logging/layouts/basic'

module Logging

  #
  # The +Appender+ class is provides methods for appending log events to a
  # logging destination. The log events are formatted into strings using a
  # Layout.
  #
  # All other Appenders inherit from this class which provides stub methods.
  # Each subclass should provide a +write+ method that will write log
  # messages to the logging destination.
  #
  # A private +sync+ method is provided for use by subclasses. It is used to
  # synchronize writes to the logging destination, and can be used by
  # subclasses to synchronize the closing or flushing of the logging
  # destination.
  #
  class Appender

    attr_reader :name, :layout

    #
    # call-seq:
    #    Appender.new( name )
    #    Appender.new( name, :layout => layout )
    #
    # Creates a new appender using the given name. If no Layout is specified,
    # then a Basic layout will be used. Any logging header supplied by the
    # layout will be written to the logging destination when the Appender is
    # created.
    #
    def initialize( name, opts = {} )
      @name = name.to_s
      @closed = false
      self.layout = opts[:layout] if opts.include? :layout
      @layout ||= ::Logging::Layouts::Basic.new

      @sync = Sync.new
      sync {write(@layout.header)}
    end

    #
    # call-seq:
    #    append( data )
    #    appender << data
    #
    # Write the given _data_ to the logging destination. If the data is a log
    # event, then it will be processed through the Layout associated with the
    # Appender.
    # 
    # If the data is a String it will be sent to the logging destination "as
    # is" -- no layout formatting will be performed. If the data is any other
    # object it will be converted to a string by calling +inspect+ on the
    # object, and that string will be sent to the logging destination "as is"
    # -- no layout formatting will be performed.
    #
    def append( data )
      if @closed
        raise RuntimeError,
              "appender '<#{self.class.name}: #{@name}>' is closed"
      end

      data = case data
             when String: data
             when ::Logging::LogEvent: @layout.format(data)
             else data.inspect end
      sync {write(data)}

      self
    end
    alias :<< :append

    #
    # call-seq
    #    appender.layout = Logging::Layouts::Basic.new
    #
    # Sets the layout to be used by this appender.
    #
    def layout=( layout )
      unless layout.kind_of? ::Logging::Layout
        raise TypeError,
              "#{layout.inspect} is not a kind of 'Logging::Layout'"
      end
      @layout = layout
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
    def close( footer = true )
      return self if @closed
      @closed = true
      sync {write(@layout.footer)} if footer
      self
    end

    #
    # call-seq:
    #    closed?
    #
    # Returns +true+ if the appender has been closed; returns +false+
    # otherwise. When an appender is closed, no more log events can be
    # written to the logging destination.
    #
    def closed?( ) @closed end

    #
    # call-seq:
    #    flush
    #
    # Call +flush+ to force an appender to write out any buffered log events.
    # Similar to IO#flush, so use in a similar fashion.
    #
    def flush( ) self end


    private 
    #
    # call-seq:
    #    write( str )
    #
    # Writes the given string to the logging destination. Subclasses should
    # provide an implementation of this method.
    #
    def write( str ) nil end

    #
    # call-seq:
    #    sync { block }
    #
    # Obtains an exclusive lock, runs the block, and releases the lock when
    # the block completes. This method is re-entrant so that a single thread
    # can call +sync+ multiple times without hanging the thread.
    #
    def sync
      if Thread.current == @sync.sync_ex_locker then yield
      else @sync.synchronize(:EX) {yield} end
    end

  end  # class Appender
end  # module Logging

# EOF

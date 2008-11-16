
module Logging

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

  @appenders = Hash.new

  class << self

    # call-seq:
    #    Appender[name]
    #
    # Returns the appender instance stroed in the Appender hash under the
    # key _name_, or +nil+ if no appender has been created using that name.
    #
    def []( name ) @appenders[name] end

    # call-seq:
    #    Appender[name] = appender
    #
    # Stores the given _appender_ instance in the Appender hash under the
    # key _name_.
    #
    def []=( name, val ) @appenders[name] = val end

    # call-seq:
    #    Appenders.remove( name )
    #
    # Removes the appender instance stored in the Appender hash under the
    # key _name_.
    #
    def remove( name ) @appenders.delete(name) end

    # call-seq:
    #    Appender.stdout
    #
    # Returns an instance of the Stdout Appender. Unless the user explicitly
    # creates a new Stdout Appender, the instance returned by this method
    # will always be the same:
    #
    #    Appender.stdout.object_id == Appender.stdout.object_id    #=> true
    #
    def stdout( ) self['stdout'] || ::Logging::Appenders::Stdout.new end

    # call-seq:
    #    Appender.stderr
    #
    # Returns an instance of the Stderr Appender. Unless the user explicitly
    # creates a new Stderr Appender, the instance returned by this method
    # will always be the same:
    #
    #    Appender.stderr.object_id == Appender.stderr.object_id    #=> true
    #
    def stderr( ) self['stderr'] || ::Logging::Appenders::Stderr.new end

  end  # class << self

  attr_reader :name, :layout, :level

  # call-seq:
  #    Appender.new( name )
  #    Appender.new( name, :layout => layout )
  #
  # Creates a new appender using the given name. If no Layout is specified,
  # then a Basic layout will be used. Any logging header supplied by the
  # layout will be written to the logging destination when the Appender is
  # created.
  #
  # Options:
  #
  #    :layout   => the layout to use when formatting log events
  #    :level    => the level at which to log
  #
  def initialize( name, opts = {} )
    @name = name.to_s
    @closed = false

    self.layout = opts.getopt(:layout, ::Logging::Layouts::Basic.new)
    self.level = opts.getopt(:level)

    @mutex = Mutex.new
    header = @layout.header

    unless header.nil? || header.empty?
      begin 
        sync {write(header)}
      rescue StandardError => err
        ::Logging.log_internal(-2) {err}
      end
    end

    ::Logging::Appender[@name] = self
  end

  # call-seq:
  #    append( event )
  #
  # Write the given _event_ to the logging destination. The log event will
  # be processed through the Layout associated with the Appender.
  #
  def append( event )
    if @closed
      raise RuntimeError,
            "appender '<#{self.class.name}: #{@name}>' is closed"
    end

    # only append if the event level is less than or equal to the configured
    # appender level
    unless @level > event.level
      begin
        sync {write(event)}
      rescue StandardError => err
        ::Logging.log_internal(-2) {err}
      end
    end

    self
  end

  # call-seq:
  #    appender << string
  #
  # Write the given _string_ to the logging destination "as is" -- no
  # layout formatting will be performed.
  #
  def <<( str )
    if @closed
      raise RuntimeError,
            "appender '<#{self.class.name}: #{@name}>' is closed"
    end

    unless @level >= ::Logging::LEVELS.length
      begin
        sync {write(str)}
      rescue StandardError => err
        ::Logging.log_internal(-2) {err}
      end
    end
    self
  end

  # call-seq:
  #    level = :all
  #
  # Set the level for this appender; log events below this level will be
  # ignored by this appender. The level can be either a +String+, a
  # +Symbol+, or a +Fixnum+. An +ArgumentError+ is raised if this is not
  # the case.
  #
  # There are two special levels -- "all" and "off". The former will
  # enable recording of all log events. The latter will disable the
  # recording of all events.
  #
  # Example:
  #
  #    appender.level = :debug
  #    appender.level = "INFO"
  #    appender.level = 4
  #    appender.level = 'off'
  #    appender.level = :all
  #
  # These prodcue an +ArgumentError+
  #
  #    appender.level = Object
  #    appender.level = -1
  #    appender.level = 1_000_000_000_000
  #
  def level=( level )
    lvl = case level
          when String, Symbol; ::Logging::level_num(level)
          when Fixnum; level
          when nil; 0
          else
            raise ArgumentError,
                  "level must be a String, Symbol, or Integer"
          end
    if lvl.nil? or lvl < 0 or lvl > ::Logging::LEVELS.length
      raise ArgumentError, "unknown level was given '#{level}'"
    end

    @level = lvl
  end

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
    ::Logging::Appender.remove(@name)
    @closed = true
    if footer
      footer = @layout.footer
      unless footer.nil? || footer.empty?
        begin
          sync {write(footer)}
        rescue StandardError => err
          ::Logging.log_internal(-2) {err}
        end
      end
    end
    self
  end

  # call-seq:
  #    closed?
  #
  # Returns +true+ if the appender has been closed; returns +false+
  # otherwise. When an appender is closed, no more log events can be
  # written to the logging destination.
  #
  def closed?
    @closed
  end

  # call-seq:
  #    flush
  #
  # Call +flush+ to force an appender to write out any buffered log events.
  # Similar to IO#flush, so use in a similar fashion.
  #
  def flush
    self
  end

  # call-seq:
  #     inspect    => string
  #
  # Returns a string representation of the appender.
  #
  def inspect
    "<%s:0x%x name=\"%s\">" % [
        self.class.name.sub(%r/^Logging::/, ''),
        self.object_id,
        self.name
    ]
  end


  private 

  # call-seq:
  #    write( event )
  #
  # Writes the given _event_ to the logging destination. Subclasses should
  # provide an implementation of this method. The _event_ can be either a
  # LogEvent or a String. If a LogEvent, then it will be formatted using
  # the layout given to the appender when it was created.
  #
  def write( event )
    nil
  end

  # call-seq:
  #    sync { block }
  #
  # Obtains an exclusive lock, runs the block, and releases the lock when
  # the block completes. This method is re-entrant so that a single thread
  # can call +sync+ multiple times without hanging the thread.
  #
  def sync
    @mutex.synchronize {yield}
  end

end  # class Appender
end  # module Logging

Logging.require_all_libs_relative_to(__FILE__, 'appenders')

# EOF


module Logging::Appenders

  # The Buffering module is used to implement buffering of the log messages
  # in a given appender. The size of the buffer can be specified, and the
  # buffer can be configured to auto-flush at a given threshold. The
  # threshold can be a single message or a very large number of messages.
  #
  # Log messages of a certain level can cause the buffer to be flushed
  # immediately. If an error occurs, all previous messages and the error
  # message will be written immediately to the logging destination if the
  # buffer is configured to do so.
  #
  module Buffering

    # Default buffer size
    #
    DEFAULT_BUFFER_SIZE = 500;

    # The buffer holding the log messages
    #
    attr_reader :buffer

    # The auto-flushing setting. When the buffer reaches this size, all
    # messages will be be flushed automatically.
    #
    attr_reader :auto_flushing

    # Call +flush+ to force an appender to write out any buffered log events.
    # Similar to IO#flush, so use in a similar fashion.
    #
    def flush
      return self if @buffer.empty?

      str = nil
      sync {
        str = @buffer.join
        @buffer.clear
      }

      canonical_write str unless str.empty?
      self
    end

    # Configure the levels that will trigger and immediate flush of the
    # logging buffer. When a log event of the given level is seen, the
    # buffer will be flushed immediately. Only the levels explicitly given
    # in this assignment will flush the buffer; if an "error" message is
    # configured to immediately flush the buffer, a "fatal" message will not
    # even though it is a higher level. Both must be explicitly passed to
    # this assignment.
    #
    # You can pass in a single leveal name or number, and array of level
    # names or numbers, or a string containg a comma separated list of level
    # names or numbers.
    #
    #   immediate_at = :error
    #   immediate_at = [:error, :fatal]
    #   immediate_at = "warn, error"
    #
    def immediate_at=( level )
      @immediate ||= []
      @immediate.clear

      # get the immediate levels -- no buffering occurs at these levels, and
      # a log message is written to the logging destination immediately
      immediate_at =
        case level
        when String; level.split(',').map {|x| x.strip}
        when Array; level
        else Array(level) end

      immediate_at.each do |lvl|
        num = ::Logging.level_num(lvl)
        next if num.nil?
        @immediate[num] = true
      end
    end

    # Configure the auto-flushing period. Auto-flushing is used to flush the
    # contents of the logging buffer to the logging destination
    # automatically when the buffer reaches a certain threshold.
    #
    # By default, the auto-flushing will be configured to flush after each
    # log message.
    #
    # The allowed settings are as follows:
    #
    #   N      : flush after every N messages (N is an integer)
    #   true   : flush after each log message
    #   false  OR
    #   nil    OR
    #   0      : only flush when the buffer is full (500 messages)
    #
    # If the default buffer size of 500 is too small, you can manuall
    # configure to be as large as you want. This will consume more memory.
    #
    #   auto_flushing = 42_000
    #
    def auto_flushing=( period )
      @auto_flushing =
        case period
        when true;             1
        when false, nil, 0;    DEFAULT_BUFFER_SIZE
        when Integer;          period
        when String;           Integer(period)
        else
          raise ArgumentError,
                "unrecognized auto_flushing period: #{period.inspect}"
        end

      if @auto_flushing < 0
        raise ArgumentError,
          "auto_flushing period cannot be negative: #{period.inspect}"
      end
    end


  protected

    # Configure the buffering using the arguments found in the give options
    # hash. This method must be called in order to use the message buffer.
    # The supported options are "immediate_at" and "auto_flushing". Please
    # refer to the documentation for those methods to see the allowed
    # options.
    #
    def configure_buffering( opts )
      ::Logging.init unless ::Logging.const_defined? :MAX_LEVEL_LENGTH

      @buffer = []
      self.immediate_at = opts.getopt(:immediate_at, '')
      self.auto_flushing = opts.getopt(:auto_flushing, true)
    end

    # Returns true if the _event_ level matches one of the configured
    # immediate logging levels. Otherwise returns false.
    #
    def immediate?( event )
      return false unless event.respond_to? :level
      @immediate[event.level]
    end


  private

    # call-seq:
    #    write( event )
    #
    # Writes the given _event_ to the logging destination. The _event_ can
    # be either a LogEvent or a String. If a LogEvent, then it will be
    # formatted using the layout given to the appender when it was created.
    #
    # The _event_ will be formatted and then buffered until the
    # "auto_flushing" level has been reached. At thsi time the canonical_write
    # method will be used to log all events stored in the buffer.
    #
    def write( event )
      str = event.instance_of?(::Logging::LogEvent) ?
            layout.format(event) : event.to_s
      return if str.empty?

      if @auto_flushing == 1
        canonical_write(str)
      else
        sync { @buffer << str }
        flush if @buffer.length >= @auto_flushing || immediate?(event)
      end

      self
    end

  end  # module Buffering
end  # module Logging::Appenders


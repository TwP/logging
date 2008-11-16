
module Logging::Appenders

  # This class provides an Appender that can write to any IO stream
  # configured for writing.
  #
  class IO < ::Logging::Appender

    # :stopdoc:
    attr_reader :buffer, :buffer_size
    private :buffer, :buffer_size
    # :startdoc:

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
      @io.sync = true if @io.respond_to?('sync') rescue nil

      @buffer_size = opts.getopt :buffer_size, 0, :as => Integer
      @buffer = @buffer_size > 0 ? [] : nil

      # get the immediate levels -- no buffering occurs at these levels, and
      # a log message is written to the IO stream immediately
      @immediate = []
      immediate_at = opts.getopt(:immediate_at, '')
      immediate_at =
        case immediate_at
        when String; immediate_at.split(',').map {|x| x.strip}
        when Array; immediate_at
        else Array(immediate_at) end
      
      immediate_at.each do |lvl|
        num = ::Logging.level_num(lvl)
        next if num.nil?
        @immediate[num] = true
      end

      super(name, opts)
    end

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
      super(*args)
      io, @io = @io, nil
      io.close unless [STDIN, STDERR, STDOUT].include?(io)
    rescue IOError => err
    ensure
      return self
    end

    # call-seq:
    #    flush
    #
    # Call +flush+ to force an appender to write out any buffered log events.
    # Similar to IO#flush, so use in a similar fashion.
    #
    def flush
      return self if @io.nil?
      flush_buffer if buffer?
      @io.flush
      self
    end


    private

    # call-seq:
    #    write( event )
    #
    # Writes the given _event_ to the IO stream. If an +IOError+ is detected,
    # than this appender will be turned off and the error reported.
    #
    def write( event )
      begin
        immediate = false
        str =
          if event.instance_of?(::Logging::LogEvent)
            immediate = immediate?(event.level)
            layout.format(event)
          else
            event.to_s
          end
        return if str.empty?

        if buffer?
          buffer << str
          flush_buffer if buffer.length >= buffer_size || immediate
        else
          @io.print str
        end
        return self
      rescue IOError
        self.level = :off
        ::Logging.log_internal {"appender #{name.inspect} has been disabled"}
        raise
      end
    end

    #
    #
    def immediate?( level )
      @immediate[level]
    end

    #
    #
    def buffer?
      !@buffer.nil?
    end

    #
    #
    def flush_buffer
      buffer.each {|str| @io.print str}
      buffer.clear
    end

  end  # class IO
end  # module Logging::Appenders

# EOF

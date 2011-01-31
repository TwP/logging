
module Logging::Appenders

  # This class provides an Appender that can write to any IO stream
  # configured for writing.
  #
  class IO < ::Logging::Appender
    include Buffering

    # call-seq:
    #    IO.new( name, io )
    #    IO.new( name, io, :layout => layout )
    #
    # Creates a new IO Appender using the given name that will use the _io_
    # stream as the logging destination.
    #
    def initialize( name, io, opts = {} )
      unless io.respond_to? :syswrite
        raise TypeError, "expecting an IO object but got '#{io.class.name}'"
      end

      @io = io
      configure_buffering(opts)
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
      super
      io, @io = @io, nil
      io.close unless [STDIN, STDERR, STDOUT].include?(io)
    rescue IOError => err
    ensure
      return self
    end


  private

    # This method is called by the buffering code when messages need to be
    # written to the logging destination.
    #
    def canonical_write( str )
      return self if @io.nil?
      @io.syswrite str
      self
    rescue StandardError => err
      self.level = :off
      ::Logging.log_internal {"appender #{name.inspect} has been disabled"}
      ::Logging.log_internal(-2) {err}
    end

  end  # class IO
end  # module Logging::Appenders



module Logging::Appenders

  # This class provides an Appender that can write to a File.
  #
  class File < ::Logging::Appenders::IO

    # call-seq:
    #    File.assert_valid_logfile( filename )    => true
    #
    # Asserts that the given _filename_ can be used as a log file by ensuring
    # that if the file exists it is a regular file and it is writable. If
    # the file does not exist, then the directory is checked to see if it is
    # writable.
    #
    # An +ArgumentError+ is raised if any of these assertions fail.
    #
    def self.assert_valid_logfile( fn )
      if ::File.exist?(fn)
        if not ::File.file?(fn)
          raise ArgumentError, "#{fn} is not a regular file"
        elsif not ::File.writable?(fn)
          raise ArgumentError, "#{fn} is not writeable"
        end
      elsif not ::File.writable?(::File.dirname(fn))
        raise ArgumentError, "#{::File.dirname(fn)} is not writable"
      end
      true
    end

    # call-seq:
    #    File.new( name, :filename => 'file' )
    #    File.new( name, :filename => 'file', :truncate => true )
    #    File.new( name, :filename => 'file', :layout => layout )
    #
    # Creates a new File Appender that will use the given filename as the
    # logging destination. If the file does not already exist it will be
    # created. If the :truncate option is set to +true+ then the file will
    # be truncated before writing begins; otherwise, log messages will be
    # appened to the file.
    #
    def initialize( name, opts = {} )
      @fn = opts.getopt(:filename, name)
      raise ArgumentError, 'no filename was given' if @fn.nil?

      @fn = ::File.expand_path(@fn)
      self.class.assert_valid_logfile(@fn)
      @mode = opts.getopt(:truncate) ? 'w' : 'a'

      super(name, ::File.new(@fn, @mode), opts)
    end

    # Returns the path to the logfile.
    #
    def filename() @fn.dup end

    # Reopen the connection to the underlying logging destination. If the
    # connection is currently closed then it will be opened. If the connection
    # is currently open then it will be closed and immediately opened.
    #
    def reopen
      @mutex.synchronize {
        if defined? @io and @io
          flush
          @io.close rescue nil
        end
        @io = ::File.new(@fn, @mode)
      }
      super
      self
    end

  end  # class FileAppender
end  # module Logging::Appenders

# EOF

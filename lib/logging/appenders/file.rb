
module Logging::Appenders

  # Accessor / Factory for the File appender.
  def self.file( *args )
    fail ArgumentError, '::Logging::Appenders::File needs a name as first argument.' if args.empty?
    ::Logging::Appenders::File.new(*args)
  end

  # This class provides an Appender that can write to a File.
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
    def self.assert_valid_logfile( fn )
      if ::File.exist?(fn)
        if !::File.file?(fn)
          raise ArgumentError, "#{fn} is not a regular file"
        elsif !::File.writable?(fn)
          raise ArgumentError, "#{fn} is not writeable"
        end
      elsif !::File.writable?(::File.dirname(fn))
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
    # appended to the file.
    def initialize( name, opts = {} )
      @filename = opts.fetch(:filename, name)
      raise ArgumentError, 'no filename was given' if @filename.nil?

      @filename = ::File.expand_path(@filename).freeze
      self.class.assert_valid_logfile(@filename)

      self.encoding = opts.fetch(:encoding, self.encoding)

      io = open_file
      super(name, io, opts)

      truncate if opts.fetch(:truncate, false)
    end

    # Returns the path to the logfile.
    attr_reader :filename

    # Reopen the connection to the underlying logging destination. If the
    # connection is currently closed then it will be opened. If the connection
    # is currently open then it will be closed and immediately opened.
    def reopen
      @mutex.synchronize {
        if defined? @io && @io
          flush
          @io.close rescue nil
        end
        @io = open_file
      }
      super
      self
    end


  protected

    def truncate
      @mutex.synchronize {
        begin
          @io.flock(::File::LOCK_EX)
          @io.truncate(0)
        ensure
          @io.flock(::File::LOCK_UN)
        end
      }
    end

    def open_file
      mode = ::File::WRONLY | ::File::APPEND
      ::File.open(filename, mode: mode, external_encoding: encoding)
    rescue Errno::ENOENT
      create_file
    end

    def create_file
      mode = ::File::WRONLY | ::File::APPEND | ::File::CREAT | ::File::EXCL
      ::File.open(filename, mode: mode, external_encoding: encoding)
    rescue Errno::EEXIST
      open_file
    end
  end
end

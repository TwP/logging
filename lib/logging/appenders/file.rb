# $Id$

require 'logging/appenders/io'

module Logging
module Appenders

  #
  # This class provides an Appender that can write to a File.
  #
  class File < ::Logging::Appenders::IO

    #
    # call-seq:
    #    File.new( filename )
    #    File.new( filename, :truncate => true )
    #    File.new( filename, :layout => layout )
    #
    # Creates a new File Appender that will use the given _filename_ as the
    # logging destination. If the file does not already exist it will be
    # created. If the :truncate option is set to +true+ then the file will be
    # truncated before writing begins; otherwise, log messages will be appened
    # to the file.
    #
    def initialize( filename, opts = {} )
      mode = opts.delete(:truncate) ? 'w' : 'a'

      if ::File.exist?(filename)
        if not ::File.file?(filename)
          raise StandardError, "#{filename} is not a regular file"
        elsif not ::File.writable?(filename)
          raise StandardError, "#{filename} is not writeable"
        end
      elsif not ::File.writable?(::File.dirname(filename))
        raise StandardError, "#{::File.dirname(filename)} is not writable"
      end

      super(filename, ::File.new(filename, mode), opts)
    end

  end  # class FileAppender
end  # module Appenders
end  # module Logging

# EOF

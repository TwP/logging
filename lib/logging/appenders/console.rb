# $Id$

require 'logging/appenders/io'

module Logging
module Appenders

  #
  # This class provides an Appender that can write to STDOUT.
  #
  class Stdout< ::Logging::Appenders::IO

    #
    # call-seq:
    #    StdOut.new
    #    StdOut.new( :layout => layout )
    #
    # Creates a new StdOut Appender. The name 'stdout' will always be used for
    # this appender.
    #
    def initialize( name = nil, opts = {} )
      name ||= 'stdout'
      STDOUT.sync = true
      super(name, STDOUT, opts)
    end
  end  # class Stdout

  #
  # This class provides an Appender that can write to STDERR.
  #
  class Stderr< ::Logging::Appenders::IO

    #
    # call-seq:
    #    StdErr.new
    #    StdErr.new( :layout => layout )
    #
    # Creates a new StdErr Appender. The name 'stderr' will always be used for
    # this appender.
    #
    def initialize( name = nil, opts = {} )
      name ||= 'stderr'
      STDERR.sync = true
      super(name, STDERR, opts)
    end
  end  # class Stderr

end  # module Appenders
end  # module Logging

# EOF

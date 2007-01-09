# $Id$

require 'logging/appenders/io'

module Logging
module Appenders

  #
  # This class provides an Appender that can write to STDOUT.
  #
  class StdOut< ::Logging::Appenders::IO

    #
    # call-seq:
    #    StdOut.new
    #    StdOut.new( :layout => layout )
    #
    # Creates a new StdOut Appender. The name 'stdout' will always be used for
    # this appender.
    #
    def initialize( opts = {} )
      super('stdout', STDOUT, opts)
    end
  end  # class StdOut

  #
  # This class provides an Appender that can write to STDERR.
  #
  class StdErr< ::Logging::Appenders::IO

    #
    # call-seq:
    #    StdErr.new
    #    StdErr.new( :layout => layout )
    #
    # Creates a new StdErr Appender. The name 'stderr' will always be used for
    # this appender.
    #
    def initialize( opts = {} )
      super('stderr', STDERR, opts)
    end
  end  # class StdErr

end  # module Appenders
end  # module Logging

# EOF

# $Id$

module Logging

  #
  # This class defines a logging event.
  #
  class LogEvent

    # :stopdoc:

    # Regular expression used to parse out caller information
    #
    # * $1 == filename
    # * $2 == line number
    # * $3 == method name (might be nil)
    CALLER_RGXP = %r/([\.\/\(\)\w]+):(\d+)(?::in `(\w+)')?/o
    # :startdoc:

    #
    # call-seq:
    #    LogEvent.new( logger, level, [data], trace )
    #
    def initialize( logger, level, data, trace )
      @logger = logger
      @level = level
      @data = data
      @file = @line = @method = ''

      if trace
        t = Kernel.caller(3)[0]
        break if t.nil?

        m = CALLER_RGXP.match(t)
        @file = m[1]
        @line = m[2]
        @method = m[3] unless m[3].nil?
      end
    end

    attr_accessor :logger, :level, :data
    attr_reader :file, :line, :method

  end  # class LogEvent
end  # module Logging

#EOF

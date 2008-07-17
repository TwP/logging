
module Logging

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

    # call-seq:
    #    LogEvent.new( logger, level, [data], trace )
    #
    # Creates a new log event with the given _logger_ name, numeric _level_,
    # array of _data_ from the user to be logged, and boolean _trace_ flag.
    # If the _trace_ flag is set to +true+ then Kernel::caller will be
    # invoked to get the execution trace of the logging method.
    #
    def initialize( logger, level, data, trace )
      @logger = logger
      @level = level
      @data = data
      @file = @line = @method = ''

      if trace
        t = Kernel.caller[2]
        return if t.nil?

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

# EOF

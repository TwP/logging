# $Id$

require 'logging/appender'

module Logging
module Appenders

  # This class provides an Appender that can send notifications to the Growl
  # notification system on Mac OS X.
  #
  # +growlnotify+ must be installed somewhere in the path in order for the
  # appender to function properly.
  #
  class Growl < ::Logging::Appender

    # call-seq:
    #    Growl.new( name, opts = {} )
    #
    # Create an appender that will log messages to the Growl framework on a
    # Mac OS X machine.
    #
    def initialize( name, opts = {} )
      super

      @growl = "growlnotify -n '#{@name}' -t '%s' -m '%s' -p %d"

      getopt = ::Logging.options(opts)
      @coalesce = getopt[:coalesce, false]

      # provides a mapping from the default Logging levels
      # to the Growl notification levels
      @map = [-2, -1, 0, 1, 2]

      map = getopt[:map]
      self.map = map unless map.nil?
    end

    # call-seq:
    #    map = { logging_levels => growl_levels }
    #
    # Configure the mapping from the Logging levels to the Growl
    # notification levels. This is needed in order to log events at the
    # proper Growl level.
    #
    # Without any configuration, the following maping will be used:
    #
    #    :debug  =>  -2
    #    :info   =>  -1
    #    :warn   =>  0
    #    :error  =>  1
    #    :fatal  =>  2
    #
    def map=( levels )
      map = []
      levels.keys.each do |lvl|
        num = ::Logging.level_num(lvl)
        map[num] = growl_level_num(levels[lvl])
      end
      @map = map
    end

    # call-seq:
    #    append( event )
    #
    # Send the given _event_ to the Growl framework. The log event will be
    # processed through the Layout assciated with this appender. The message
    # will be logged at the level specified by the event.
    #
    def append( event )
      if closed?
        raise RuntimeError,
              "appender '<#{self.class.name}: #{@name}>' is closed"
      end

      sync do
        title = ''
        message = @layout.format(event)
        priority = @map[event.level]
        growl(title, message, priority)
      end unless @level > event.level
      self
    end

    # call-seq:
    #    syslog << string
    #
    # Write the given _string_ to the Growl framework "as is" -- no
    # layout formatting will be performed. The string will be logged at the
    # 0 notification level of the Growl framework.
    #
    def <<( str )
      if closed?
        raise RuntimeError,
              "appender '<#{self.class.name}: #{@name}>' is closed"
      end

      title = ''
      message = str
      sync {growl(title, message, 0)}
      self
    end


    private

    # call-seq:
    #    growl_level_num( level )    => integer
    #
    # Takes the given _level_ as a string or integer and returns the
    # corresponding Growl notification level number.
    #
    def growl_level_num( level )
      level = case level
              when Integer: level
              when String: Integer(level)
              else raise ArgumentError, "unkonwn level '#{level}'" end
      if level < -2 or level > 2
        raise ArgumentError, "level '#{level}' is not in range -2..2"
      end
      level
    end

    # call-seq:
    #    growl( title, message, priority )
    #
    def growl( title, message, priority )
      system @growl % [title, message, priority]
    end

  end  # class Growl

end  # module Appenders
end  # module Logging

# EOF

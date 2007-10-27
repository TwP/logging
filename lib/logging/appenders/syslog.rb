# $Id$

require 'logging/appender'
require 'syslog'

module Logging
module Appenders

  # This class provides an Appender that can write to STDOUT.
  #
  class Syslog < ::Logging::Appender
    include ::Syslog::Constants

    def initialize( name, opts = {} )
      super
      ident = opts[:ident] || opts['ident'] || name 
      logopt = opts[:logopt] || opts['logopt'] || (LOG_PID | LOG_CONS)
      facility = opts[:facility] || opts['facility'] || LOG_USER
      @syslog = ::Syslog.open(ident, Integer(logopt), Integer(facility))

      # provides a mapping from the default Logging levels
      # to the syslog levels
      self.map = [LOG_DEBUG, LOG_INFO, LOG_WARNING, LOG_ERR, LOG_CRIT]
    end

    def map=( levels )
      @map = levels.dup
    end

    def close
      @syslog.close
    end

    def closed?
      !@syslog.opened?
    end

    def append( event )
      if closed?
        raise RuntimeError,
              "appender '<#{self.class.name}: #{@name}>' is closed"
      end

      sync do
        msg = @layout.format(event)
        pri = @map[event.level]
        @syslog.log(pri, msg)
      end unless @level > event.level
      self
    end

    def <<( str )
      if closed?
        raise RuntimeError,
              "appender '<#{self.class.name}: #{@name}>' is closed"
      end

      sync {@syslog.log(LOG_DEBUG, str)}
      self
    end

  end  # class Syslog

end  # module Appenders
end  # module Logging

# EOF

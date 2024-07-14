
module Logging
  module Appenders

    # call-seq:
    #    Appenders[name]
    #
    # Returns the appender instance stored in the appender hash under the
    # key _name_, or +nil+ if no appender has been created using that name.
    #
    def []( name ) @appenders[name] end

    # call-seq:
    #    Appenders[name] = appender
    #
    # Stores the given _appender_ instance in the appender hash under the
    # key _name_.
    #
    def []=( name, value ) @appenders[name] = value end

    # call-seq:
    #    Appenders.remove( name )
    #
    # Removes the appender instance stored in the appender hash under the
    # key _name_.
    #
    def remove( name ) @appenders.delete(name) end

    # call-seq:
    #    each {|appender| block}
    #
    # Yield each appender to the _block_.
    #
    def each( &block )
      @appenders.values.each(&block)
      return nil
    end

    # :stopdoc:
    def reset
      @appenders.values.each {|appender|
        next if appender.nil?
        appender.close
      }
      @appenders.clear
      return nil
    end
    # :startdoc:

    # Accessor / Factory for the Syslog appender.
    #
    def self.syslog( *args )
      fail ArgumentError, '::Logging::Appenders::Syslog needs a name as first argument.' if args.empty?
      ::Logging::Appenders::Syslog.new(*args)
    end

    extend self
    @appenders = Hash.new

    # Load Syslog only when requested. Windows does not have syslog, and
    # Ruby 3.4.0 will remove it from the standard library. Requiring
    # syslog on Ruby 3.3.0 will result in an warning if the gem is not
    # explicitly installed.
    autoload :Syslog, Logging.libpath('logging/appenders/syslog')
  end  # Appenders

  require libpath('logging/appenders/buffering')
  require libpath('logging/appenders/io')
  require libpath('logging/appenders/console')
  require libpath('logging/appenders/file')
  require libpath('logging/appenders/rolling_file')
  require libpath('logging/appenders/string_io')
end  # Logging


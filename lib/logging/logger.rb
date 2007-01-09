# $Id$

require 'logging'
require 'logging/appender'
require 'logging/logger_repository'


module Logging

  #
  # Defines a logging event. This structure contains the name of the logger
  # that generated the logging event, the logging level name, and the data
  # to be logged.
  #
  LogEvent = Struct.new( :logger, :level, :data )

  #
  # The +Logger+ class is the primary interface to the +Logging+ framework.
  # It provides the logging methods that will be called from user methods,
  # and it generates logging events that are sent to the appenders (the
  # appenders take care of sending the log events to the logging
  # destinations -- files, sockets, etc).
  #
  # +Logger+ instances are obtained from the +LoggerRepository+ and should
  # not be directly created by users.
  #
  # Example:
  #
  #    log = Logging::Logger['my logger']
  #    log.add( Logging::Appenders::StdOut.new )   # append to STDOUT
  #    log.level = :info                           # log 'info' and above
  #
  #    log.info 'starting foo operation'
  #    ...
  #    log.info 'finishing foo operation'
  #    ...
  #    log.fatal 'unknown exception', exception
  #
  class Logger

    class << self
      #
      # call-seq:
      #    Logger[name]
      #
      # Returns the +Logger+ named _name_. If the logger does not exist it
      # will be created.
      #
      # When _name_ is a +String+ or a +Symbol+ it will be used "as is" to
      # retrieve the logger. When _name_ is a +Class+ the class name will be
      # used to retrieve the logger. When _name_ is an object the name of the
      # object's class will be used to retrieve the logger.
      #
      # Example:
      #
      #   obj = MyClass.new
      #   log1 = Logger[obj]
      #   log2 = Logger[MyClass]
      #   log3 = Logger['MyClass']
      #
      #   log1.object_id == log2.object_id         # => true
      #   log2.object_id == log3.object_id         # => true
      #
      def []( name ) ::Logging::LoggerRepository.instance[name] end

      #
      # call-seq:
      #    Logger.fetch( name )
      #
      # Returns the +Logger+ named _name_. An +IndexError+ will be raised if
      # the logger does not exist.
      #
      # When _name_ is a +String+ or a +Symbol+ it will be used "as is" to
      # retrieve the logger. When _name_ is a +Class+ the class name will be
      # used to retrieve the logger. When _name_ is an object the name of the
      # object's class will be used to retrieve the logger.
      #
      def fetch( name ) ::Logging::LoggerRepository.instance.fetch(name) end

      #
      # nodoc:
      #
      # This is where the actual logging methods are defined. Two methods
      # are created for each log level. The first is a query method used to
      # determine if that perticular logging level is enabled. The second is
      # the actual logging method that accepts a list of objects to be
      # logged or a block. If a block is given, then the object returned
      # from the block will be logged.
      #
      # Example
      #
      #    log = Logging::Logger['my logger']
      #    log.level = :warn
      #
      #    log.info?                               # => false
      #    log.warn?                               # => true
      #    log.warn 'this is your last warning'
      #    log.fatal 'I die!', exception
      #
      #    log.debug do
      #      # expensive method to construct log message
      #      msg
      #    end
      #
      def define_log_methods( logger )
        ::Logging::LEVELS.each do |sym,num|
          if logger.level > num
            module_eval <<-CODE
              def logger.#{sym}?( ) false end
              def logger.#{sym}( *args ) false end
            CODE
          else
            module_eval <<-CODE
              def logger.#{sym}?( ) true end
              def logger.#{sym}( *args )
                args.push yield if block_given?
                log_event(LogEvent.new(@name, '#{::Logging::LNAMES[sym]}', args)) unless args.empty?
                true
              end
            CODE
          end
        end
      end
    end

    #  nodoc:
    def self.new( *args )
      unless caller[0] =~ %r/logger_repository.rb:\d+:/
        raise RuntimeError,
              "use 'Logging::Logger[name]' to obtain Logger instances"
      end
      super(*args)
    end

    attr_reader :level, :name, :parent
    attr_accessor :additive

    #
    # call-seq:
    #    Logger.new( name )
    #
    # Returns a new logger identified by _name_.
    #
    def initialize( name )
      case name
      when String:
        raise(ArgumentError, "logger must have a name") if name.empty?
      else raise(ArgumentError, "logger name must be a String") end

      repo = ::Logging::LoggerRepository.instance
      @name = name
      @parent = repo.parent(name)
      @appenders = []
      @additive = true
      self.level = @parent.level

      repo.children(name).each {|c| c.parent = self}
    end

    #
    # call-seq:
    #    log <=> other
    #
    # Compares this logger by name to another logger. The normal return codes
    # for +String+ objects apply.
    #
    def <=>( other )
      case other
      when self: 0
      when ::Logging::RootLogger: 1
      when ::Logging::Logger: @name <=> other.name
      else super end
    end

    #
    # call-seq:
    #    log << "message"
    #
    # Log the given message without any formatting and without performing any
    # level checks. The message is logged to all appenders. The message is
    # passed up the logger tree if this logger's additivity is +true+.
    #
    def <<( msg )
      @appenders.each {|a| a << msg}
      @parent << msg if @additive
    end

    #
    # call-seq:
    #    level = :all
    #
    # Set the level for this logger. The level can be either a +String+, a
    # +Symbol+, or a +Fixnum+. An +ArgumentError+ is raised if this is not
    # the case.
    #
    # There are two special levels -- "all" and "off". The former will
    # enable log messages from this logger. The latter will disable all log
    # messages from this logger.
    #
    # Setting the logger level to +nil+ will cause the parent's logger level
    # to be used.
    #
    # Example:
    #
    #    log.level = :debug
    #    log.level = "INFO"
    #    log.level = 4
    #    log.level = 'off'
    #    log.level = :all
    #
    # These prodcue an +ArgumentError+
    #
    #    log.level = Object
    #    log.level = -1
    #    log.level = 1_000_000_000_000
    #
    def level=( level )
      lvl = case level
            when String, Symbol:
              lvl = ::Logging::levelify level
              case lvl
              when :all: 0
              when :off: ::Logging::LEVELS.length
              else ::Logging::LEVELS[lvl] end
            when Fixnum: level
            when nil: @parent.level
            else
              raise ArgumentError,
                    "level must be a String, Symbol, or Integer"
            end
      if lvl.nil? or lvl < 0 or lvl > ::Logging::LEVELS.length
        raise ArgumentError, "unknown level was given '#{level}'"
      end

      @level = lvl
      ::Logging::Logger.define_log_methods(self)
      @level
    end

    #
    # call-seq:
    #    appenders = app
    #
    # Clears the current list of appenders and replaces them with _app_,
    # where _app_ can be either a single appender or an array of appenders.
    #
    def appenders=( args )
      @appenders.clear
      add *args unless args.nil?
    end

    #
    # call-seq:
    #    add( appenders )
    #
    # Add the given _appenders_ to the list of appenders, where _appenders_
    # can be either a single appender or an array of appenders.
    #
    def add( *args )
      args.each do |arg|
        unless arg.kind_of? ::Logging::Appender
          raise TypeError,
                "#{arg.inspect} is not a kind of 'Logging::Appender'"
        end
        @appenders << arg unless @appenders.include? arg
      end
    end

    #
    # call-seq:
    #    remove( appenders )
    #
    # Remove the given _appenders_ from the list of appenders. The appenders
    # to remove can be identified either by name using a +String+ or by
    # passing the appender instance. _appenders_ can be a single appender or
    # an array of appenders.
    #
    def remove( *args )
      args.each do |arg|
        @appenders.delete_if do |a|
          case arg
          when String: arg == a.name
          when ::Logging::Appender: arg.object_id == a.object_id
          else
            raise TypeError, "#{arg.inspect} is not a 'Logging::Appender'"
          end
        end
      end
    end

    #
    # call-seq:
    #    clear
    #
    # Remove all appenders from this logger.
    #
    def clear( ) @appenders.clear end


    protected
    #
    # call-seq:
    #    parent = ParentLogger
    #
    # Set the parent logger for this logger. This method will be invoked by
    # the +LoggerRepository+ class when a parent or child is added to the
    # hierarchy.
    #
    def parent=( parent ) @parent = parent end

    #
    # call-seq:
    #    log_event( event )
    #
    # Send the given _event_ to the appenders for logging, and pass the
    # _event_ up to the parent if additive mode is enabled. The log level has
    # already been checked before this method is called.
    #
    def log_event( event )
      @appenders.each {|a| a.append(event)}
      @parent.log_event(event) if @additive
    end

  end  # class Logger


  #
  # The root logger exists to ensure that all loggers have a parent and a
  # defined logging level. If a logger is additive, eventually its log
  # events will propogate up to the root logger.
  #
  class RootLogger < Logger

    # undefine the methods that the root logger does not need
    %w(additive additive= parent parent=).each do |m|
      undef_method m.intern
    end

    #
    # call-seq:
    #    RootLogger.new
    #
    # Returns a new root logger instance. This method will be called only
    # once when the +LoggerRepository+ singleton instance is created.
    #
    def initialize( )
      unless ::Logging.const_defined? 'MAX_LEVEL_LENGTH'
        ::Logging.define_levels %w(debug info warn error fatal)
      end

      @name = 'root'
      @appenders = []
      @additive = false
      self.level = 0
    end

    #
    # call-seq:
    #    log <=> other
    #
    # Compares this logger by name to another logger. The normal return codes
    # for +String+ objects apply.
    #
    def <=>( other )
      case other
      when self: 0
      when ::Logging::Logger: -1
      else super end
    end

    #
    # call-seq:
    #    level = :all
    #
    # Set the level for the root logger. The functionality of this method is
    # the same as +Logger#level=+, but setting the level to +nil+ for the
    # root logger is not allowed. The level is silently set to :all.
    #
    def level=( level )
      level ||= 0
      super
    end

  end  # class RootLogger
end  # module Logging

# EOF

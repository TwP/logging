# $Id$

require 'logging/logger_repository'

# require all appenders
require 'logging/appenders/console'
require 'logging/appenders/file'

# require all layouts
require 'logging/layouts/basic'
require 'logging/layouts/pattern'


#
#
#
module Logging

  LEVELS = {}  # :nodoc:
  LNAMES = {}  # :nodoc:

  class << self
    #
    # call-seq:
    #    define_levels( levels )
    #
    # Defines the levels available to the loggers. The _levels_ is an array
    # of strings and symbols. Each element in the array is downcased and
    # converted to a symbol; these symbols are used to create the logging
    # methods in the loggers.
    #
    # The first element in the array is the lowest logging level. Setting the
    # logging level to this value will enable all log messages. The last
    # element in the array is the highest logging level. Setting the logging
    # level to this value will disable all log messages except this highest
    # level.
    #
    # This method should only be invoked once to configure the logging
    # levels. It is automatically invoked with the default logging levels
    # when the first logger is created.
    #
    # The levels "all" and "off" are reserved and will be ignored if passed
    # to this method.
    #
    # Example:
    #
    #    Logging.define_levels :debug, :info, :warn, :error, :fatal
    #    log = Logging::Logger['my logger']
    #    log.level = :warn
    #    log.warn 'Danger! Danger! Will Robinson'
    #    log.info 'Just FYI'                        # => not logged
    #
    # or
    #
    #    Logging.define_levels %w(DEBUG INFO NOTICE WARNING ERR CRIT ALERT EMERG)
    #    log = Logging::Logger['syslog']
    #    log.level = :notice
    #    log.warning 'This is your first warning'
    #    log.info 'Just FYI'                        # => not logged
    #
    def define_levels( *args )
      return nil if args.empty?

      args.flatten!
      levels = ::Logging::LEVELS.clear
      names = ::Logging::LNAMES.clear

      id = 0
      args.each do |lvl|
        lvl = levelify lvl
        unless levels.has_key? lvl or lvl == :all or lvl == :off
          levels[lvl] = id 
          names[lvl] = lvl.to_s.upcase
          id += 1
        end
      end

      longest = names.values.inject {|x,y| (x.length > y.length) ? x : y}
      module_eval "MAX_LEVEL_LENGTH = #{longest.length}"

      levels.keys
    end
   
    #
    # call-seq:
    #    format_as( obj_format )
    #
    # Defines the default _obj_format_ method to use when converting objects
    # into string representations for logging. _obj_format_ can be one of
    # <tt>:string</tt>, <tt>:inspect</tt>, or <tt>:yaml</tt>. These
    # formatting commands map to the following object methods
    #
    # * :string  => to_s
    # * :inspect => inspect
    # * :yaml    => to_yaml
    #
    # An +ArgumentError+ is raised if anything other than +:string+,
    # +:inspect+, +:yaml+ is passed to this method.
    #
    def format_as( f )
      unless [:string, :inspect, :yaml].include? f
        raise ArgumentError, "unknown object format '#{f}'"
      end

      module_eval "OBJ_FORMAT = :#{f}"
    end

    # :stopdoc:
    def levelify( level )
      case level
      when String: level.downcase.intern
      when Symbol: level.to_s.downcase.intern
      else raise ArgumentError, "levels must be a String or Symbol" end
    end
    # :startdoc:
  end

end  # module Logging

# EOF

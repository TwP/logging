# $Id$

require 'logging/appenders/console'

module Logging
class Appender

  @appenders = Hash.new

  class << self

    #
    # call-seq:
    #    Appender[name]
    #
    # Returns the appender instance stroed in the Appender hash under the
    # key _name_, or +nil+ if no appender has been created using that name.
    #
    def []( name ) @appenders[name] end

    #
    # call-seq:
    #    Appender[name] = appender
    #
    # Stores the given _appender_ instance in the Appender hash under the
    # key _name_.
    #
    def []=( name, val ) @appenders[name] = val end

    #
    # call-seq:
    #    Appender.stdout
    #
    # Returns an instance of the Stdout Appender. Unless the user explicitly
    # creates a new Stdout Appender, the instance returned by this method
    # will always be the same:
    #
    #    Appender.stdout.object_id == Appender.stdout.object_id    #=> true
    #
    def stdout( ) self['stdout'] || ::Logging::Appenders::Stdout.new end

    #
    # call-seq:
    #    Appender.stderr
    #
    # Returns an instance of the Stderr Appender. Unless the user explicitly
    # creates a new Stderr Appender, the instance returned by this method
    # will always be the same:
    #
    #    Appender.stderr.object_id == Appender.stderr.object_id    #=> true
    #
    def stderr( ) self['stderr'] || ::Logging::Appenders::Stderr.new end

  end  # class << self
end  # class Appender
end  # module Logging

# EOF

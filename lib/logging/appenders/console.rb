module Logging::Appenders

  # This class is provides an Appender base class for writing to the standard IO
  # stream - STDOUT and STDERR. This class should not be instantiated directly.
  # The `Stdout` and `Stderr` subclasses should be used.
  class Console < ::Logging::Appenders::IO

    # call-seq:
    #    Stdout.new( name = 'stdout' )
    #    Stderr.new( :layout => layout )
    #    Stdout.new( name = 'stdout', :level => 'info' )
    #
    # Creates a new Stdout/Stderr Appender. The name 'stdout'/'stderr' will be
    # used unless another is given. Optionally, a layout can be given for the
    # appender to use (otherwise a basic appender will be created) and a log
    # level can be specified.
    #
    # Options:
    #
    #    :layout => the layout to use when formatting log events
    #    :level  => the level at which to log
    #
    def initialize( *args )
      name = self.class.name.split("::").last.downcase

      opts = args.last.is_a?(Hash) ? args.pop : {}
      name = args.shift unless args.empty?

      io = open_fd
      opts[:encoding] = io.external_encoding

      super(name, io, opts)
    end

    # Reopen the connection to the underlying logging destination. If the
    # connection is currently closed then it will be opened. If the connection
    # is currently open then it will be closed and immediately reopened.
    def reopen
      @mutex.synchronize {
        flush if defined? @io && @io
        @io = open_fd
      }
      super
      self
    end

  private

    def open_fd
      case self.class.name
      when "Logging::Appenders::Stdout"; STDOUT
      when "Logging::Appenders::Stderr"; STDERR
      else
        raise RuntimeError, "Please do not use the `Logging::Appenders::Console` class directly - " +
                            "use `Logging::Appenders::Stdout` and `Logging::Appenders::Stderr` instead" +
                            " [class #{self.class.name}]"
      end
    end
  end

  # This class provides an Appender that can write to STDOUT.
  Stdout = Class.new(Console)

  # This class provides an Appender that can write to STDERR.
  Stderr = Class.new(Console)

  # Accessor / Factory for the Stdout appender.
  def self.stdout( *args )
    if args.empty?
      return self['stdout'] || ::Logging::Appenders::Stdout.new
    end
    ::Logging::Appenders::Stdout.new(*args)
  end

  # Accessor / Factory for the Stderr appender.
  def self.stderr( *args )
    if args.empty?
      return self['stderr'] || ::Logging::Appenders::Stderr.new
    end
    ::Logging::Appenders::Stderr.new(*args)
  end
end


module Logging

  #
  #
  module MappedDiagnosticContext
    extend self

    # The name used to retrieve the MDC from thread-local storage.
    NAME = 'logging.mapped-diagnostic-context'.freeze

    # Public:
    #
    def []=( key, value )
      context.store(key.to_s, value)
    end

    # Public:
    #
    def []( key )
      context.fetch(key.to_s, nil)
    end

    # Public:
    #
    def delete( key )
      context.delete(key.to_s)
    end

    # Public:
    #
    def clear
      context.clear
      self
    end

    #
    #
    def inherit( thread )
      raise ArgumentError, "Expecting a Thread to inherit context from" unless Thread === thread
      return if Thread.current == thread

      Thread.exclusive {
        Thread.current[NAME] = thread[NAME].dup if thread[NAME]
      }

      self
    end

    # Returns the Hash acting as the storage for this NestedDiagnosticContext.
    # A new storage Hash is created for each Thread running in the
    # application.
    #
    def context
      Thread.current[NAME] ||= Hash.new
    end
  end  # MappedDiagnosticContext

  #
  #
  module NestedDiagnosticContext
    extend self

    # The name used to retrieve the NDC from thread-local storage.
    NAME = 'logging.nested-diagnostic-context'.freeze

    # Public:
    #
    def push( val )
      context.push(val.to_s)
      self
    end
    alias :<< :push

    # Public:
    #
    def pop
      context.pop
    end

    # Public:
    #
    def peek
      context.last
    end

    # Public:
    #
    def clear
      context.clear
      self
    end

    #
    #
    def inherit( thread )
      raise ArgumentError, "Expecting a Thread to inherit context from" unless Thread === thread
      return if Thread.current == thread

      Thread.exclusive {
        Thread.current[NAME] = thread[NAME].dup if thread[NAME]
      }

      self
    end

    # Returns the Array acting as the storage stack for this
    # MappedDiagnosticContext. A new storage Array is created for each Thread
    # running in the application.
    #
    def context
      Thread.current[NAME] ||= Array.new
    end
  end  # NestedDiagnosticContext

  # Public: Accessor method for getting the current Thread's
  # MappedDiagnosticContext.
  #
  def self.mdc() MappedDiagnosticContext end

  # Public: Accessor method for getting the current Thread's
  # NestedDiagnosticContext.
  #
  def self.ndc() NestedDiagnosticContext end

end  # module Logging


# :stopdoc:
class Thread
  class << self
    alias :_orig_new :new

    # In order for the diagnostic contexts to behave properly we need to
    # inherit state from the parent thread. The only way I have found to do
    # this in Ruby is to override `new` and capture the parent Thread at the
    # time of child Thread creation. The code below does just this. If there
    # is a more idiomatic way of accomplishing this in Ruby, please let me
    # know!
    #
    def new( *a, &b )
      _orig_new( Thread.current, *a ) { |parent, *args|
        Logging::MappedDiagnosticContext.inherit(parent)
        Logging::NestedDiagnosticContext.inherit(parent)
        b.call(*args)
      }
    end
  end
end  # Thread
# :startdoc:


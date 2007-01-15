# $Id$

require 'singleton'
require 'logging/root_logger'


module Logging

  #
  # The Repository is a hash that stores references to all Loggers
  # that have been created. It provides methods to determine parent/child
  # relationships between Loggers and to retrieve Loggers from the hash.
  #
  class Repository
    include Singleton

    PATH_DELIMITER = '::'  # :nodoc:

    #
    # nodoc:
    #
    # This is a singleton class -- use the +instance+ method to obtain the
    # +Repository+ instance.
    #
    def initialize
      @h = {:root => ::Logging::RootLogger.new}
    end

    #
    # call-seq:
    #    instance[name]
    #
    # Returns the +Logger+ named _name_.
    #
    # When _name_ is a +String+ or a +Symbol+ it will be used "as is" to
    # retrieve the logger. When _name_ is a +Class+ the class name will be
    # used to retrieve the logger. When _name_ is an object the name of the
    # object's class will be used to retrieve the logger.
    #
    # Example:
    #
    #   repo = Repository.instance
    #   obj = MyClass.new
    #
    #   log1 = repo[obj]
    #   log2 = repo[MyClass]
    #   log3 = repo['MyClass']
    #
    #   log1.object_id == log2.object_id         # => true
    #   log2.object_id == log3.object_id         # => true
    #
    def []( key ) @h[to_key(key)] end

    #
    # call-seq:
    #    instance[name] = logger
    #
    # Stores the _logger_ under the given _name_.
    #
    # When _name_ is a +String+ or a +Symbol+ it will be used "as is" to
    # store the logger. When _name_ is a +Class+ the class name will be
    # used to store the logger. When _name_ is an object the name of the
    # object's class will be used to store the logger.
    #
    def []=( key, val ) @h[to_key(key)] = val end

    #
    # call-seq:
    #    fetch( name )
    #
    # Returns the +Logger+ named _name_. An +IndexError+ will be raised if
    # the logger does not exist.
    #
    # When _name_ is a +String+ or a +Symbol+ it will be used "as is" to
    # retrieve the logger. When _name_ is a +Class+ the class name will be
    # used to retrieve the logger. When _name_ is an object the name of the
    # object's class will be used to retrieve the logger.
    #
    def fetch( key ) @h.fetch(to_key(key)) end

    #
    # call-seq:
    #    parent( key )
    #
    # Returns the parent logger for the logger identified by _key_ where
    # _key_ follows the same identification rules described in
    # +Repository#[]+. A parent is returned regardless of the
    # existence of the logger referenced by _key_.
    #
    def parent( key )
      key = to_key(key)
      a = key.split PATH_DELIMITER

      p = @h[:root]
      while a.slice!(-1) and !a.empty?
        k = a.join PATH_DELIMITER
        if @h.has_key? k then p = @h[k]; break end
      end
      p
    end

    #
    # call-seq:
    #    children( key )
    #
    # Returns an array of the children loggers for the logger identified by
    # _key_ where _key_ follows the same identification rules described in
    # +Repository#[]+. Children are returned regardless of the
    # existence of the logger referenced by _key_.
    #
    def children( key )
      key = to_key(key)
      depth = key.split(PATH_DELIMITER).length
      rgxp = Regexp.new "^#{key}#{PATH_DELIMITER}"

      a = @h.keys.map do |k|
            if k =~ rgxp
              l = @h[k]
              d = l.parent.name.split(PATH_DELIMITER).length
              if d <= depth then l else nil end
            end
          end
      a.compact.sort
    end

    #
    # call-seq:
    #    to_key( key )
    #
    # Takes the given _key_ and converts it into a form that can be used to
    # retrieve a logger from the +Repository+ hash.
    #
    # When _key_ is a +String+ or a +Symbol+ it will be returned "as is".
    # When _key_ is a +Class+ the class name will be returned. When _key_ is
    # an object the name of the object's class will be returned.
    #
    def to_key( key )
      case key
      when Symbol, String: key
      when Class: key.name
      when Object: key.class.name
      end
    end

  end  # class Repository
end  # module Logging

# EOF

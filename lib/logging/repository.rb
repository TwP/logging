# $Id$

require 'singleton'
require 'logging/logger'


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
      @h = Hash.new {|h,k| h.synchronize(:EX) {h[k] = ::Logging::Logger.new(k)}}
      @h[:root] = ::Logging::RootLogger.new
      @h.extend Sync_m
    end

    #
    # call-seq:
    #    instance[key]
    #
    # See the documentation for +Logger#[]+.
    #
    def []( key ) @h[to_key(key)] end

    #
    # call-seq:
    #    fetch( key )
    #
    # See the documentation for +Logger#fetch+.
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

      @h.synchronize(:SH) do
        p = @h[:root]
        while a.slice!(-1) and !a.empty?
          k = a.join PATH_DELIMITER
          if @h.has_key? k then p = @h[k]; break end
        end
        p
      end
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

      @h.synchronize(:SH) do
        a = @h.keys.map do |k|
              if k =~ rgxp
                l = @h[k]
                d = l.parent.name.split(PATH_DELIMITER).length
                if d <= depth then l else nil end
              end
            end
        a.compact.sort
      end
    end


    private
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

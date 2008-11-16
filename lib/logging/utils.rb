
class Hash

  # call-seq:
  #    getopt( key, default = nil, :as => class )
  #
  # Returns the value associated with the _key_. If the has does not contain
  # the _key_, then the _default_ value is returned.
  #
  # Optionally, the value can be converted into to an instance of the given
  # _class_. The supported classes are:
  #
  #     Integer
  #     Float
  #     Array
  #     String
  #     Symbol
  #
  # If the value is +nil+, then no converstion will be performed.
  #
  def getopt( *args )
    opts = args.last.instance_of?(Hash) ? args.pop : {}
    key, default = args

    val = if has_key?(key);                self[key]
          elsif has_key?(key.to_s);        self[key.to_s]
          elsif has_key?(key.to_s.intern); self[key.to_s.intern]
          else default end

    return if val.nil?
    return val unless opts.has_key?(:as)

    case opts[:as].name.intern
    when :Integer; Integer(val)
    when :Float;   Float(val)
    when :Array;   Array(val)
    when :String;  String(val)
    when :Symbol;  String(val).intern
    else val end
  end
end

class String

  # call-seq:
  #    reduce( width, ellipses = '...' )    #=> string
  #
  # Reduce the size of the current string to the given _width_ by removing
  # characters from the middle of the string and replacing them with
  # _ellipses_. If the _width_ is greater than the length of the string, the
  # string is returned unchanged. If the _width_ is less than the length of
  # the _ellipses_, then the _ellipses_ are returned.
  #
  def reduce( width, ellipses = '...')
    raise ArgumentError, "width cannot be negative: #{width}" if width < 0

    return self if length <= width

    remove = length - width + ellipses.length
    return ellipses.dup if remove >= length

    left_end = (length + 1 - remove) / 2
    right_start = left_end + remove

    left = self[0,left_end]
    right = self[right_start,length-right_start]

    left << ellipses << right
  end
end

class Module

  # call-seq:
  #    logger_name    #=> string
  #
  # Returns a predictable logger name for the current module or class. If
  # used within an anonymous class, the first non-anonymous class name will
  # be used as the logger name. If used within a meta-class, the name of the
  # actual class will be used as the logger name. If used within an
  # anonymous module, the string 'anonymous' will be returned.
  #
  def logger_name
    return name unless name.empty?

    # check if this is a metaclass (or eigenclass)
    if ancestors.include? Class
      inspect =~ %r/#<Class:([^#>]+)>/
      return $1
    end

    # see if we have a superclass
    if respond_to? :superclass
      return superclass.logger_name
    end

    # we are an anonymous module
    ::Logging.log_internal(-2) {
      'cannot return a predictable, unique name for anonymous modules'
    }
    return 'anonymous'
  end
end

class ReentrantMutex < Mutex

  def initialize
    super
    @locker = nil
  end

  alias :original_synchronize :synchronize

  def synchronize
    if @locker == Thread.current
      yield
    else
      original_synchronize {
        begin
          @locker = Thread.current
          yield
        ensure
          @locker = nil
        end
      }
    end
  end
end  # class ReentrantMutex

# EOF

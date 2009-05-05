
# --------------------------------------------------------------------------
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

# --------------------------------------------------------------------------
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

# --------------------------------------------------------------------------
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
    return name unless name.nil? or name.empty?

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

# --------------------------------------------------------------------------
module Kernel

  # Settiing this global variable to +false+ will disable rubygems from
  # being loaded at all.
  $use_rubygems = true unless defined? $use_rubygems

  # Setting this global variable to +true+ will cause an error message to be
  # displayed when a library cannot be required.
  $whiny_require = false unless defined? $whiny_require

  # call-seq:
  #    require!( string )
  #    require!( string, gem_version )
  #    require!( string, gem_name, gem_version )
  #
  # Attempt to the load the library named _string_ using the standard
  # Kernel#require method. If the library cannot be loaded then require
  # rubygems and retry the original require of the library.
  #
  # Raises a LoadError if the library cannot be loaded.
  #
  # If a _gem_version_ is given, then the rubygems +gem+ command is used to
  # load the specific version of the gem. The library _string_ is used for
  # the _gem_name_ if one is omitted.
  #
  def require!( string, *args )
    return require(string) if args.empty?

    name, version = *args
    version, name = name, string if name =~ %r/^[0-9<>=~]/
    version ||= '> 0'

    gem name, version
    require(string)
  rescue LoadError, NoMethodError
    retry if $use_rubygems and require('rubygems')
    if $whiny_require
      name ||= string
      $stderr.puts "Required library #{string.inspect} could not be loaded."
      $stderr.puts "Try:\tgem install #{name}"
    end
    raise
  end

  # call-seq:
  #    require?( string )
  #    require?( string, gem_version )
  #    require?( string, gem_name, gem_version )
  #
  # Attempt to the load the library named _string_ using the standard
  # Kernel#require method. If the library cannot be loaded then require
  # rubygems and retry the original require of the library.
  #
  # Returns +true+ if the library was successfully loaded. Returns +false+
  # if the library could not be loaded. This method will never raise an
  # exception.
  #
  # If a _gem_version_ is given, then the rubygems +gem+ command is used to
  # load the specific version of the gem. The library _string_ is used for
  # the _gem_name_ if one is omitted.
  #
  def require?( string, *args )
    wr, $whiny_require = $whiny_require, false
    require!(string, *args)
    return true
  rescue LoadError
    return false
  ensure
    $whiny_require = wr
  end
end  # module Kernel

# --------------------------------------------------------------------------
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

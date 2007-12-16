# $Id$

require 'test/unit'

# This line is needed for Ruby 1.9 -- hashes throw a "KeyError" in 1.9
# whereas they throw an "IndexError" in 1.8
#
KeyError = IndexError if not defined? KeyError

begin
  require 'rubygems'
  require 'logging'
rescue LoadError
  path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
  raise if $:.include? path
  $: << path
  retry
end

begin
  require 'turn'
rescue LoadError
  require 'rubygems'
  begin; require 'turn'; rescue LoadError; end
end


module TestLogging
module LoggingTestCase

  def setup
    super

    ::Logging.module_eval do
      ::Logging::LEVELS.clear
      ::Logging::LNAMES.clear
      remove_const :MAX_LEVEL_LENGTH if const_defined? :MAX_LEVEL_LENGTH
      remove_const :OBJ_FORMAT if const_defined? :OBJ_FORMAT
    end

    ::Logging::Repository.class_eval do
      if defined?(@singleton__instance__)
        @singleton__instance__ = nil
      else
        @__instance__ = nil
        class << self
          nonce = class << Singleton; self; end
          define_method(:instance, nonce::FirstInstanceCall)
        end
      end
    end
    
    ::Logging::Appender.instance_variable_get(:@appenders).clear
  end

end  # module LoggingTestCase
end  # module TestLogging

# EOF

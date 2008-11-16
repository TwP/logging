
# Equivalent to a header guard in C/C++
# Used to prevent the class/module from being loaded more than once
unless defined? LOGGING_TEST_SETUP
LOGGING_TEST_SETUP = true

require 'rubygems'
require 'test/unit'
require 'fileutils'
require 'stringio'
begin
  require 'turn'
rescue LoadError; end

# This line is needed for Ruby 1.9 -- hashes throw a "KeyError" in 1.9
# whereas they throw an "IndexError" in 1.8
#
KeyError = IndexError if not defined? KeyError

require File.join(File.dirname(__FILE__), %w[.. lib logging])


module TestLogging
module LoggingTestCase

  TMP = 'tmp'

  def setup
    super

    FileUtils.rm_rf TMP
    FileUtils.mkdir TMP

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
  end
    
  def teardown
    super
    ::Logging.backtrace
    ::Logging.__send__(:remove_instance_variable, :@backtrace)
    h = ::Logging::Appender.instance_variable_get(:@appenders)
    h.each_value {|a| a.close(false) unless a.nil? || a.closed?}
    h.clear
    FileUtils.rm_rf TMP
  end

end  # module LoggingTestCase
end  # module TestLogging

end  # unless defined?

# EOF

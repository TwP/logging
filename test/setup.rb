# $Id$

require 'test/unit'

begin
  require 'logging'
rescue LoadError
  require 'rubygems'
  require 'logging'
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

      ::Logging::LoggerRepository.class_eval do
        @__instance__ = nil
        class << self
          nonce = class << Singleton; self; end
          define_method(:instance, nonce::FirstInstanceCall)
        end
      end
    end

  end  # module LoggingTestCase
end  # module TestLogging

# EOF

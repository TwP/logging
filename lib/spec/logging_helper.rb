
module Spec
  module LoggingHelper

    # Capture log messages from the Logging framework and make them
    # available via a @log_output instance variable. The @log_output
    # supports a readline method to access the log messags.
    #
    def capture_log_messages( opts = {} )
      from = opts[:from] || 'root'
      to = opts[:to] || '__rspec__'

      logger = Logging::Logger[from]
      logger.appenders = Logging::Appender[to] || Logging::Appenders::StringIo.new(to)

      before(:all) do
        @log_output = Logging::Appender[to]
      end

      before(:each) do
        @log_output.reset
      end
    end

  end  # module LoggingHelper
end  # module Spec

# EOF

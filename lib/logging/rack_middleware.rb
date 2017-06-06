require 'logging'

module Logging
  # Reliably log errors and clear the MDC
  class RackMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call(env)
    rescue => e
      Logging.logger[self].error(e)
      raise
    ensure
      Logging.mdc.clear
    end
  end
end

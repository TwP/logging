require 'set'

module Logging
  module Filters

    # The `Level` filter class provides a simple level-based filtering mechanism
    # that allows events whose log level matches a preconfigured list of values.
    class Level < ::Logging::Filter

      # Creates a new level filter that will only allow the given _levels_ to
      # propagate through to the logging destination. The _levels_ should be
      # given in symbolic form.
      #
      # Examples
      #     Logging::Filters::Level.new(:debug, :info)
      #
      def initialize(*levels)
        super()
        levels  = levels.flatten.map {|level| ::Logging::level_num(level)}
        @levels = Set.new(levels)
      end

      # Returns the event if it should be forwarded to the logging appender.
      # Otherwise, `nil` is returned. The log event is allowed if the
      # `event.level` matches one of the levels provided to the filter when it
      # was constructred.
      def allow(event)
        @levels.include?(event.level) ? event : nil
      end
    end
  end
end
